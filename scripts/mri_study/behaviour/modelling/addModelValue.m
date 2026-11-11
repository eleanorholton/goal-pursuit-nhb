%% Functions to add model values to data table 

    % Input:
        % data table
        % number of iterations to run sampler
        % path to find sampler parameters 
        
    % Output:
        % data table with values from models: offer-max, myopic, simple
        % prospective, sampler 

function data_table = addModelValue(data_table, n_sampler_itr,homepath)


% define goal item, bestalt, worstalt matrix indices (excluding first trials)
gi = data_table.goal_item_idx(data_table.trial_number>1)'; 
ba = data_table.best_alt_idx(data_table.trial_number>1)'; 
wa = data_table.worst_alt_idx(data_table.trial_number>1)';

gi_matidx = sub2ind([numel(gi) max(gi)],1:numel(gi),gi);
ba_matidx = sub2ind([numel(ba) max(ba)],1:numel(ba),ba);
wa_matidx = sub2ind([numel(wa) max(wa)],1:numel(wa),wa);

%% 1. Offer-max value
data_table.offer_max_value = data_table.mag_best_alt - data_table.mag_goal_item; 

%% 2. Myopic value of net item = net item offer + current contents of net; for alternatives myopic value = magnitude

% Add full myopic value to data table
data_table.myopic_values = data_table.magnitudes; 

% edit goal item myopic magnitudes to add net contents 
myopic_cut = data_table.myopic_values(data_table.trial_number>1,:); 
myopic_cut(gi_matidx) = data_table.mag_goal_item(data_table.trial_number>1) + data_table.net_contents(data_table.trial_number>1); 

data_table.myopic_values(data_table.trial_number>1,:) = myopic_cut; 

% add switch value and item category value 
data_table.myopic_goal_item = NaN(height(data_table),1); 
data_table.myopic_goal_item(data_table.trial_number>1) = diag(data_table.myopic_values(data_table.trial_number>1,data_table.goal_item_idx(data_table.trial_number>1))); 

data_table.myopic_best_alt = NaN(height(data_table),1); 
data_table.myopic_best_alt(data_table.trial_number>1) = diag(data_table.myopic_values(data_table.trial_number>1,data_table.best_alt_idx(data_table.trial_number>1))); 

data_table.myopic_worst_alt = NaN(height(data_table),1); 
data_table.myopic_worst_alt(data_table.trial_number>1) = diag(data_table.myopic_values(data_table.trial_number>1,data_table.worst_alt_idx(data_table.trial_number>1))); 

data_table.myopic_switch_value = data_table.myopic_best_alt - data_table.myopic_goal_item; % Switch value = best alternative offer - myopic value of net item 


%% 3. Simple prospective values

[data_table.prosp_goal_item_1, data_table.prosp_best_alt_1, data_table.prosp_worst_alt_1, data_table.prosp_switch_value_1] = addSimpleProspective_L1(data_table.mag_goal_item, data_table.mag_best_alt, data_table.mag_worst_alt, data_table.net_contents, data_table.goal_size); 
[data_table.prosp_goal_item_2, data_table.prosp_best_alt_2, data_table.prosp_worst_alt_2, data_table.prosp_switch_value_2] = addSimpleProspective_L2(data_table.mag_goal_item, data_table.mag_best_alt, data_table.mag_worst_alt, data_table.net_contents, data_table.goal_size); 
[data_table.prosp_goal_item_3, data_table.prosp_best_alt_3, data_table.prosp_worst_alt_3, data_table.prosp_switch_value_3] = addSimpleProspective_L3(data_table.mag_goal_item, data_table.mag_best_alt, data_table.mag_worst_alt, data_table.net_contents, data_table.goal_size); 

%% 6. Sampler value 

% Load in parameters used to make schedules (for sampler model) 
sched_params = load([homepath, '/data/mri_study/behaviour/schedule_info/sched_params.mat']);
sched_params = sched_params.sched_params; 

temperature=NaN; 

nTrials = height(data_table); 

% Cannot use data_table in parfor loop so need to assign variables, and
% then add variables to data table after

sampler_choice = NaN(nTrials,1); 
sampler_values = NaN(nTrials,3); 
sampler_goal_item = NaN(nTrials,1); 
sampler_best_alt= NaN(nTrials,1); 
sampler_worst_alt= NaN(nTrials,1); 
sampler_uncertainty_goal_item = NaN(nTrials,1); 
sampler_uncertainty_best_alt= NaN(nTrials,1); 
sampler_uncertainty_worst_alt= NaN(nTrials,1); 
sampler_estimated_proximity = NaN(nTrials,1); 


sampler_goal_item = NaN(nTrials,1); 
sampler_best_alt= NaN(nTrials,1); 
sampler_worst_alt= NaN(nTrials,1);

all_mags = data_table.magnitudes; 
goal_size = data_table.goal_size; 
trial_nums = data_table.trial_number; 
net_contents = data_table.net_contents; 

goal_item_idx = data_table.goal_item_idx;
best_alt_idx = data_table.best_alt_idx;
worst_alt_idx = data_table.worst_alt_idx;

parfor t = 1:height(data_table)
    
        disp(['starting sampler trial ', num2str(t)]); 
        
        trialPosition = t; 
        magnitudes = all_mags(t,:); 
        
        [sampler_choice(t), ~, sampler_estimated_proximity(t), ~,samplerValues, samplerCertainty] =  evaluateOptions(magnitudes, net_contents(t), goal_item_idx(t), goal_size(t), n_sampler_itr, sched_params.var, sched_params.cut_off, sched_params.p_jumpUp, sched_params.p_jumpLo, sched_params.xmax, sched_params.xmin, sched_params.jumpHi, sched_params.jumpLo, temperature, trialPosition,sched_params.startingMean,0,0, 0);

        sampler_values(t,:) = samplerValues;

       if trial_nums(t)>1
           
        sampler_goal_item(t) = samplerValues(goal_item_idx(t)); 
        sampler_best_alt(t) = samplerValues(best_alt_idx(t));
        sampler_worst_alt(t) = samplerValues(worst_alt_idx(t));

        sampler_uncertainty_goal_item(t) = samplerCertainty(goal_item_idx(t));
        sampler_uncertainty_best_alt(t) = samplerCertainty(best_alt_idx(t));
        sampler_uncertainty_worst_alt(t) = samplerCertainty(worst_alt_idx(t));


       end


end

data_table.sampler_choice = sampler_choice;
data_table.sampler_values = sampler_values;
data_table.sampler_goal_item = sampler_goal_item;
data_table.sampler_best_alt= sampler_best_alt;
data_table.sampler_worst_alt= sampler_worst_alt;
data_table.sampler_uncertainty_goal_item =  sampler_uncertainty_goal_item;
data_table.sampler_uncertainty_best_alt= sampler_uncertainty_best_alt;
data_table.sampler_uncertainty_worst_alt= sampler_uncertainty_worst_alt;
data_table.sampler_estimated_proximity = sampler_estimated_proximity;


data_table.sampler_goal_item = sampler_goal_item;
data_table.sampler_best_alt= sampler_best_alt;
data_table.sampler_worst_alt= sampler_worst_alt;
data_table.sampler_switch_value = data_table.sampler_best_alt - data_table.sampler_goal_item; 

end      

