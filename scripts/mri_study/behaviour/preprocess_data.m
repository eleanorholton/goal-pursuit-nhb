%% Prepare environment 
clear all;
close all;

homepath = '';


addpath(genpath(homepath)); 
participantInfo=readtable([homepath, '/data/mri_study/behaviour/schedule_info/schedules.xlsx']); 


%% spatial data or non-spatial data?

spatial_data = 1;

if spatial_data
    processed_data_path = [homepath, '/data/mri_study/behaviour/processed/post_scan_session/'];
    raw_data_path = [homepath, '/data/mri_study/behaviour/raw/post_scan_session/'];
else
    processed_data_path = [homepath, '/data/mri_study/behaviour/processed/scan_session/'];
    raw_data_path = [homepath, '/data/mri_study/behaviour/raw/scan_session/'];
end



%% Processing settings

original_IDs = {'021','023','025','026','027','028','029','030','031','032','033','034','035','036','037','038','039','040','041','042','044','045','046','047','048','049','050','051','052'}; % list original participant IDs to pre-process

participants = [0:29]; % list original participant IDs to pre-process

add_models = 1; 
n_sampler_itr = 20000; 

%% Import data

all_data=cell(1,numel(participants));

for p = 1:numel(participants)
    
    ID = participants(p);
    
    if spatial_data
        
         all_data{p} = readtable([raw_data_path, 'sub_',num2str(ID),'_postScan_raw.csv']);
            
    else
         all_data{p} = readtable([raw_data_path, 'sub_',num2str(ID), '.csv']);
        
    end     
  
end

%% Pre-process data table


aggregateTable = [];


for p = 1:length(all_data)
    
    % Get participant parameters and block variables 
    scheduleID=participantInfo.scheduleID(participantInfo.behav_ID==str2double(original_IDs(p))); % schedule ID info saved separately 
    
    blockStarts = all_data{1,p}.test_trial_no==1 & all_data{1,p}.showUpdate_thisRepN==0; % isolate start of each block 
    goal_lengths = all_data{1,p}.goalSize(blockStarts); % find goal lengths for each block 
    blockNumber = all_data{1,p}.loopBlocks_thisN(blockStarts); % 0:nBlocks-1 ordered array 
    
    % Preallocate data table 
    data_table = [];
    
    nBlocks = max(blockNumber)+1; % Add 1 because coded in python

    nTrials_total=0;
   
    for b = 1:nBlocks
        
        % isolate block trials
        select_trial = find(all_data{1,p}.block_number==b);
        select_trial_full = select_trial + [-4:0];
        trial_idx = sort(select_trial(:)); % make sure trials in order 
     
        trialChoices = all_data{1,p}(trial_idx,:);

        nTrials = sum(all_data{1,p}.block_number==b);
        nTrials_total = nTrials_total + nTrials; 
        
        % get trial data 
        choice = trialChoices.choice(~isnan(trialChoices.choice));
        magnitudes = [rmmissing(trialChoices.fish_val), rmmissing(trialChoices.octopus_val), rmmissing(trialChoices.crab_val)];
        val_itm1 = rmmissing(trialChoices.fish_val); 
        val_itm2 = rmmissing(trialChoices.octopus_val);
        val_itm3 = rmmissing(trialChoices.crab_val);
        choice_onset_time = rmmissing(trialChoices.fish_value_image_started); % choice onset = when offer options appear on screen
        net_contents_end = rmmissing(trialChoices.bucketContents);
        net_contents_start = [0; net_contents_end(1:end-1)]; % need to factor in that original bucketContents variable is amount at the end of the trial rather than pre-decision amount
        
        trial_number = rmmissing(trialChoices.trial_number);
        total_trial_number = rmmissing(trialChoices.total_trial_number);
        switch_trial = rmmissing(trialChoices.switch_trial);    
       

        if spatial_data % extract spatial task responses 
            
            decisionrt = rmmissing(trialChoices.choice_click_time); 
            
            full_trial_dat =  all_data{1,p}(sort(select_trial_full(:)),:);

            % Add spatial specific regressors 
            responseOrder = rmmissing(full_trial_dat.randomiseSpatialResp_thisIndex);
            responseOrder = reshape(responseOrder,3,length(responseOrder)/3)';

            itm1_xloc = full_trial_dat.fish_x(~isnan(full_trial_dat.choice));
            itm1_xresp = full_trial_dat.locationClick_x(full_trial_dat.randomiseSpatialResp_thisIndex==0); 
            itm1_yloc = full_trial_dat.fish_y(~isnan(full_trial_dat.choice));
            itm1_yresp = full_trial_dat.locationClick_y(full_trial_dat.randomiseSpatialResp_thisIndex==0); 

            itm1_RT = full_trial_dat.locationClick_time(full_trial_dat.randomiseSpatialResp_thisIndex==0); 

            itm2_xloc = full_trial_dat.octopus_x(~isnan(full_trial_dat.choice));
            itm2_xresp = full_trial_dat.locationClick_x(full_trial_dat.randomiseSpatialResp_thisIndex==1);
            itm2_yloc = full_trial_dat.octopus_y(~isnan(full_trial_dat.choice));
            itm2_yresp = full_trial_dat.locationClick_y(full_trial_dat.randomiseSpatialResp_thisIndex==1);

            itm2_RT = full_trial_dat.locationClick_time(full_trial_dat.randomiseSpatialResp_thisIndex==1); 

            itm3_xloc = full_trial_dat.crab_x(~isnan(full_trial_dat.choice));
            itm3_xresp = full_trial_dat.locationClick_x(full_trial_dat.randomiseSpatialResp_thisIndex==2);
            itm3_yloc = full_trial_dat.crab_y(~isnan(full_trial_dat.choice));
            itm3_yresp = full_trial_dat.locationClick_y(full_trial_dat.randomiseSpatialResp_thisIndex==2);

            itm3_RT = full_trial_dat.locationClick_time(full_trial_dat.randomiseSpatialResp_thisIndex==2); 

            itm1_err = sqrt((itm1_xloc-itm1_xresp).^2+(itm1_yloc-itm1_yresp).^2);
            itm2_err = sqrt((itm2_xloc-itm2_xresp).^2+(itm2_yloc-itm2_yresp).^2);
            itm3_err = sqrt((itm3_xloc-itm3_xresp).^2+(itm3_yloc-itm3_yresp).^2);
        
        end
        
        if spatial_data
            
            block_data = table(repmat(participants(p),length(trial_number),1), repmat(participants(p),length(trial_number),1),repmat(scheduleID,length(trial_number),1),repmat(b, length(trial_number),1), trial_number, total_trial_number, repmat(goal_lengths(b), length(trial_number),1),magnitudes,choice, net_contents_start, net_contents_end, switch_trial,choice_onset_time,itm1_xloc, itm1_yloc, itm2_xloc, itm2_yloc, itm3_xloc, itm3_yloc, itm1_xresp,itm1_yresp, itm2_xresp, itm2_yresp, itm3_xresp, itm3_yresp, itm1_RT, itm2_RT, itm3_RT, responseOrder,itm1_err,itm2_err, itm3_err,decisionrt,'VariableNames',{'participant','original_ID','scheduleID','block','trial_number','total_trial_number','goal_size','magnitudes','choice', 'net_contents','net_contents_end','switch_trial','choice_onset_time','itm1_xloc', 'itm1_yloc', 'itm2_xloc', 'itm2_yloc', 'itm3_xloc', 'itm3_yloc', 'itm1_xresp', 'itm1_yresp', 'itm2_xresp', 'itm2_yresp', 'itm3_xresp', 'itm3_yresp', 'itm1_RT', 'itm2_RT', 'itm3_RT', 'responseOrder','itm1_err','itm2_err','itm3_err','decisionRT'}); 
                
        else
            
        	block_data = table(repmat(participants(p),length(trial_number),1), repmat(participants(p),length(trial_number),1),repmat(scheduleID,length(trial_number),1),repmat(b, length(trial_number),1), trial_number, total_trial_number, repmat(goal_lengths(b), length(trial_number),1),magnitudes,choice, net_contents_start, net_contents_end, switch_trial,choice_onset_time,'VariableNames',{'participant','original_ID','scheduleID','block','trial_number','total_trial_number','goal_size','magnitudes','choice', 'net_contents','net_contents_end','switch_trial','choice_onset_time'}); 
      
        end
        
        data_table = [data_table; block_data]; 
        
    end
    
    data_table = addRegressors(data_table, add_models,n_sampler_itr,homepath);  
    
    if spatial_data
        %save(strcat([processed_data_path,'post_sub_',str(participants(p),'.mat']),'data_table'); 
    else
        %save(strcat([processed_data_path,'scan_sub_',str(participants(p),'.mat']),'data_table'); 
    end
    aggregateTable = [aggregateTable; data_table]; 
    

end

%% Save as csv files 
for p = 1:numel(participants) 
    
    if spatial_data
        load([processed_data_path,'post_scan_sub_',participants(p),'.mat']); 
        writetable(data_table,[processed_data_path, 'post_scan_sub_',participants(p),'.csv']);
    else
        load([processed_data_path,'scan_sub_',participants(p),'.mat']); 
        writetable(data_table,[processed_data_path, 'scan_sub_',participants(p),'.csv']);
    end
end

