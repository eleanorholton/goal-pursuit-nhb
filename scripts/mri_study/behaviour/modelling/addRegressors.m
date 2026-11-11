
% Script to extract and add regressors to data table:

    % goal_item_idx and mag_goal_item = Identity of item currently in net, and the
    % magnitude of the offer for that item
    % best_alt_idx/worst_alt_idx = identity of best and worst alternative items
    % mag_best_alt/mag_worst_alt = magnitudes on offer for the two alternative items
    % trials_invested = number of trials without switching item choice
    % prop_filled = proportion filled: net_contents / goal_length 
    % net_contents = what's currently in the net when the decision is made (so always 0 on trial 1). Note that in the raw data tables netContents is misleading because it's the contents at the end of the trial 
    % raw_distance = how much of the net to fill: goal length - net contents 

% add_models: adds the model value regressors to the table (takes much longer)

    % Myopic value = pure magnitude for alternative items; net contents + item value for chosen option
    % Simple prospective value =  - estimated steps to achieve goal, where estimated steps to achieve goal is net size / magnitude (for alternatives), and (net size - net contents) / magntide (for chosen) 
        % Note: negative raw magnitudes are manually set to -1000. 
    % Sampler value =  - estimated steps to achieve goal, where estimated steps to achieve goal is computed by iteratively sampling over possible paths
        % Note 1: we use the sampler which can switch within the simulation
        % Note 2: Further option to add_noJumping_sampler means also doing a sampler which has probability of jumping set to 0 (an ignorant sampler) 

function data_table = addRegressors(data_table, add_models,n_sampler_itr,homepath)

%% Check only pre-processing one participant at a time – this matters for normalisation 
if numel(unique(data_table.participant))>1
    disp('WARNING: more than one participant data set is being preprocessed at once')
end

%% Define delta magnitudes 
data_table.deltaMagnitudes = [NaN NaN NaN; diff(data_table.magnitudes)]; 
data_table.deltaMagnitudes(data_table.trial_number==1,:) = repmat([NaN NaN NaN], sum(data_table.trial_number==1),1); 

%% Define chosen vs. alternative items 

% Item number of chosen vs alternatives
data_table.goal_item_idx = [NaN; data_table.choice(1:end-1)]; % the item previously chosen
data_table.goal_item_idx(data_table.trial_number==1)=NaN; % avoid carrying net item over to new block 
data_table.best_alt_idx = NaN(height(data_table),1); 
data_table.worst_alt_idx = NaN(height(data_table),1); 

% Item value of chosen vs alternatives 
data_table.mag_goal_item = NaN(height(data_table),1); 
data_table.mag_best_alt = NaN(height(data_table),1); 
data_table.mag_worst_alt = NaN(height(data_table),1); 

for t = 1:height(data_table)
    
    if data_table.trial_number(t)==1 
        
        continue; % empty net on first trial 
        
    else
        
        % Identify the option magnitudes of the chosen option, and best and worst
        % alternatives
        
        alts = setdiff(1:3, data_table.goal_item_idx(t)); % alternative items = two options not chosen on the last trial
        data_table.mag_goal_item(t) = data_table.magnitudes(t,data_table.goal_item_idx(t));
        [data_table.mag_best_alt(t), idx] = max(data_table.magnitudes(t,alts)); % find value and index of best (maximum) alternative option
        data_table.best_alt_idx(t) = alts(idx); 
        data_table.worst_alt_idx(t) = alts((idx*-1)+3); % Find the other of the two alts
        data_table.mag_worst_alt(t) = data_table.magnitudes(t,data_table.worst_alt_idx(t)); 
         
    end
    
end

%% Add basic regressors 

% trials_invested = number of sequential trials choosing this option 

data_table.trials_invested = NaN(height(data_table),1); 
pursuit_count = 0; 

for t=1:height(data_table)
    
    if data_table.trial_number(t)==1 % Not pursuing anything on first trial
        pursuit_count = 0;
    elseif data_table.switch_trial(t-1)==0 % Count trials pursuing same option
        pursuit_count=pursuit_count+1;
    elseif data_table.switch_trial(t-1)==1 % After switching, pursuit_count=1
        pursuit_count=1; 
    end
    
    data_table.trials_invested(t)=pursuit_count;
end

% Proportion filled = net contents / net size 
data_table.prop_filled = data_table.net_contents./data_table.goal_size; 
data_table.prop_filled(data_table.trial_number==1)=0; 

% Raw distance = net size - net contents
data_table.raw_distance = data_table.goal_size - data_table.net_contents;

% Chosen goes negative = trials where the chosen item first becomes
% negative (but was positive on the previous trial). 
data_table.chosen_goes_negative = [0; sign(diff(sign(data_table.mag_goal_item)))==-1];



if add_models == 1 
    
    data_table=addModelValue(data_table,n_sampler_itr,homepath); 
    
end