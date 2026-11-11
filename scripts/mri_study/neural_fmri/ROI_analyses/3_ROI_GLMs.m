%% Script to run GLMs within region of interests

    % 1. Illustration of main regressors from whole-brain analysis within regions of interest
    % 2. Interaction between goal progress and value sensitivity (using value difference)
    % 3. Interaction between goal progress and value components (split by current goal vs. best alternative goal) 
    % 4. Illustration of (3) by binning the data

% For statistical tests and to plot the GLMs as in the manuscript, see
% Figures3_and_4_ROI_results.m

% Last edited 10/8/2023, Eleanor Holton


%% Parameters

clear all; close all; 

base_folder = ''; 
addpath(genpath(base_folder)); 

% Define data and script paths 
data_folder = [base_folder, 'data/mri_study/'];
script_folder = [base_folder, 'scripts/mri_study/neural_fmri']; 

timecourse_analyses = [data_folder, 'models/'];

behav_dat = [data_folder, 'behaviour/processed/scan_session/']; 
neural_dat = [data_folder, 'neural/'];

% Participants
subjList = [0:29];

% ROIs
regions = {'ACC_decision_peak','vmPFC_decision_peak','striatum_decision_peak'};
region_idx = 1:numel(regions); 

% GLM parameters across all models
saveModel = 1; % save GLM model outputs 
intercept = 1; % include intercept in GLMs

%% Load data

% Load behavioural data
aggregateTable = []; 
for p = 1:numel(subjList) 
    
    data_table = readtable([behav_dat, 'scan_sub_',num2str(subjList(p)),'.csv']); 
    aggregateTable = [aggregateTable; data_table]; 
    
end 

% Load neural data
timefolder = fullfile([neural_dat,'ROI']);

% Load scanner timings 
load(strcat([neural_dat, '/MRI_timing_file']));


%% Upsample time course by decision onset 

nParticipants = numel(subjList); 
upsampledData = upsample_tc(timefolder,mri_timings,regions,subjList); 
individuals_choiceOnset = upsampledData.choiceOnset;
choiceOnset = individuals_choiceOnset;
regions = cell(numel(choiceOnset.Region),1); 
for reg = 1:numel(choiceOnset.Region)
    regions{reg} = choiceOnset.Region(reg).name;
end

%% Add log reaction times from scanner

aggregateTable.choiceRTs = NaN(height(aggregateTable),1);
aggregateTable.norm_log_RT = NaN(height(aggregateTable),1);

for p = 1:numel(subjList)
    
    nRuns = numel(mri_timings.onsets.choice_onset.participant{p}.run); 
    
    for r = 1:nRuns
        
        trials = mri_timings.trial_indices.participant{p}.run{r};
        choiceRTs_tmp = mri_timings.onsets.choice_resp.participant{p}.run{r} - mri_timings.onsets.choice_onset.participant{p}.run{r}; 
        aggregateTable.choiceRTs(aggregateTable.participant==subjList(p)&ismember(aggregateTable.total_trial_number,trials),:) = choiceRTs_tmp; 
        
    end
    
    aggregateTable.norm_log_RT(aggregateTable.participant==subjList(p)) = normalize(log(aggregateTable.choiceRTs(aggregateTable.participant==subjList(p)))); 
    
end

%% Add additional regressors for GLMS 

% Prepare regressors
% switch vs stay regressor 
aggregateTable.switchVsStay = aggregateTable.switch_trial;
aggregateTable.switchVsStay(aggregateTable.switchVsStay==0)=-1; 

% Value difference regressor
aggregateTable.value_difference = aggregateTable.sampler_best_alt - aggregateTable.sampler_goal_item; 

% Residualise value regressors and normalise everything at participant level 
aggregateTable.norm_resid_sampler_goal_item = NaN(height(aggregateTable),1); 
aggregateTable.norm_resid_sampler_best_alt = NaN(height(aggregateTable),1); 
aggregateTable.norm_resid_sampler_worst_alt = NaN(height(aggregateTable),1); 
aggregateTable.norm_prop_filled = NaN(height(aggregateTable),1); 
aggregateTable.norm_goal_size = NaN(height(aggregateTable),1); 
aggregateTable.norm_switchVsStay = NaN(height(aggregateTable),1); 

% Residualise value (match the code generating the whole brain ROIregressors) 
for p = 1:numel(subjList)
    
    % Run GLMs at participant level to get value residuals 
    goal_item_mdl = fitglm(aggregateTable(aggregateTable.participant==subjList(p),:), 'sampler_goal_item ~ goal_size + prop_filled');
    best_alt_mdl = fitglm(aggregateTable(aggregateTable.participant==subjList(p),:), 'sampler_best_alt ~ goal_size + prop_filled');
    worst_alt_mdl = fitglm(aggregateTable(aggregateTable.participant==subjList(p),:), 'sampler_worst_alt ~ goal_size + prop_filled + sampler_best_alt');

    % Collect residuals
    goal_item_resids = goal_item_mdl.Residuals.Raw;
    best_alt_resids = best_alt_mdl.Residuals.Raw;
    worst_alt_resids = worst_alt_mdl.Residuals.Raw; 
    
    % Normalize and add to table
    aggregateTable.norm_resid_sampler_goal_item(aggregateTable.participant==subjList(p)) = normalize(goal_item_resids); 
    aggregateTable.norm_resid_sampler_best_alt(aggregateTable.participant==subjList(p)) = normalize(best_alt_resids); 
    aggregateTable.norm_resid_sampler_worst_alt(aggregateTable.participant==subjList(p)) = normalize(worst_alt_resids); 
    
    % Normalize additional regressors in whole brain GLM
    aggregateTable.norm_prop_filled(aggregateTable.participant==subjList(p)) = normalize(aggregateTable.prop_filled(aggregateTable.participant==subjList(p))); 
    aggregateTable.norm_goal_size(aggregateTable.participant==subjList(p)) = normalize(aggregateTable.goal_size(aggregateTable.participant==subjList(p))); 
    aggregateTable.norm_switchVsStay(aggregateTable.participant==subjList(p)) = normalize(aggregateTable.switchVsStay(aggregateTable.participant==subjList(p))); 
    aggregateTable.norm_value_difference(aggregateTable.participant==subjList(p)) = normalize(aggregateTable.value_difference(aggregateTable.participant==subjList(p))); 
    aggregateTable.norm_current_goal_value(aggregateTable.participant==subjList(p)) = normalize(aggregateTable.sampler_goal_item(aggregateTable.participant==subjList(p))); 
    aggregateTable.norm_best_alt_goal_value(aggregateTable.participant==subjList(p)) = normalize(aggregateTable.sampler_best_alt(aggregateTable.participant==subjList(p))); 
    
end


% Replace NaNs with zeros before using regressor in GLM  
aggregateTable.norm_resid_sampler_goal_item(isnan(aggregateTable.norm_resid_sampler_goal_item))=0; 
aggregateTable.norm_resid_sampler_best_alt(isnan(aggregateTable.norm_resid_sampler_best_alt))=0; 
aggregateTable.norm_resid_sampler_worst_alt(isnan(aggregateTable.norm_resid_sampler_worst_alt))=0;
aggregateTable.norm_switchVsStay(aggregateTable.trial_number==1) = 0; 
aggregateTable.norm_prop_filled(isnan(aggregateTable.norm_prop_filled))=0; 
aggregateTable.norm_value_difference(isnan(aggregateTable.norm_value_difference))=0;
aggregateTable.norm_current_goal_value(isnan(aggregateTable.norm_current_goal_value))=0;
aggregateTable.norm_best_alt_goal_value(isnan(aggregateTable.norm_best_alt_goal_value))=0;
    

%% GLM 1: Illustrate whole-brain glm within ROIs

modelName = 'whole_brain_analysis_GLM';
regressors= {'norm_log_RT','norm_switchVsStay','norm_prop_filled','norm_goal_size','norm_resid_sampler_goal_item','norm_resid_sampler_best_alt','norm_resid_sampler_worst_alt'};

nRegressors = numel(regressors); 

% GLM settings
intercept = 1; % model intercept

nModels = 1;
GLM_output = cell(nModels,1);


[GLM_output{1}.betas,GLM_output{1}.SE, GLM_output{1}.tStat] = run_tc_GLM_byRun(choiceOnset, subjList, aggregateTable,  regressors,intercept, region_idx);
GLM_output{1}.name = 'all trials';

if saveModel
    output_folder = [neural_dat,'models/',modelName];
    save_model_output(GLM_output, choiceOnset, regressors, intercept, regions, subjList, output_folder);
end

%% GLM 2: Interaction between goal progress and value sensitivity (value difference)

% To match behavioural analysis: interaction between goal progress and impact of abandonment value (best alt goal - current goal)  
% Controlling for RT and switch trials (on top of main effects) 
 
modelName = 'value_difference_interaction_analysis';
aggregateTable.value_x_goal_progress = aggregateTable.norm_prop_filled .* aggregateTable.norm_value_difference;
regressors= {'norm_log_RT','norm_switchVsStay','norm_prop_filled','norm_value_difference','value_x_goal_progress'};

nRegressors = numel(regressors); 
nModels = 1;
GLM_output = cell(nModels,1);


[GLM_output{1}.betas,GLM_output{1}.SE, GLM_output{1}.tStat] = run_tc_GLM_byRun(choiceOnset, subjList, aggregateTable,  regressors,intercept, region_idx);
GLM_output{1}.name = 'all trials';

if saveModel
    output_folder = [neural_dat,'models/',modelName];
    save_model_output(GLM_output, choiceOnset, regressors, intercept, regions, subjList, output_folder);
end

% GLM 3: Interaction between goal progress and value components (split by current goal vs. best alternative goal) 

% Match behavioural analysis: interaction between goal progress and impact
% of each value component 
% Controlling for RT and switch trials (on top of main effects) 

modelName = 'value_component_interaction_analysis';

aggregateTable.curr_value_x_progress = aggregateTable.norm_prop_filled .* aggregateTable.norm_current_goal_value;
aggregateTable.alt_value_x_progress = aggregateTable.norm_prop_filled .* aggregateTable.norm_best_alt_goal_value;

regressors= {'norm_log_RT','norm_switchVsStay','norm_prop_filled','norm_current_goal_value','norm_best_alt_goal_value','curr_value_x_progress','alt_value_x_progress'};

nRegressors = numel(regressors); 

% GLM settings
intercept = 1; % model intercept
nModels = 1;
GLM_output = cell(nModels,1);


[GLM_output{1}.betas,GLM_output{1}.SE, GLM_output{1}.tStat] = run_tc_GLM_byRun(choiceOnset, subjList, aggregateTable,  regressors,intercept, region_idx);
GLM_output{1}.name = 'all trials';

if saveModel
    output_folder = [neural_dat,'models/',modelName];
    save_model_output(GLM_output, choiceOnset, regressors, intercept, regions, subjList, output_folder);
end

% GlM within bins to illustrate interaction effect 

% Settings
numSplits = 6; 
splitType = 2; % 1 = splits into equal quantities of data, in order of proportion filled; 2 = splits into groups by absolute proportion filled (i.e. 1/3, 2/3 through the net)
onlyStays = 0; 
[goalItem_split, bestAlt_split, intercepts] = progressSplits(aggregateTable, numSplits, splitType, aggregateTable.norm_current_goal_value,aggregateTable.norm_best_alt_goal_value); 

modelName = 'illustration_interaction_binned'; 

for bin = 1:numSplits
    
    % Define the column names
    chosenName = strcat('chosen_bin',num2str(bin)); % current goal value 
    bestAltName = strcat('bestAlt_bin',num2str(bin)); % best alternative goal value 
    interceptName = strcat('intercept_bin',num2str(bin)); % separate intercept for each bin (to capture general bias separately to value sensitivity)  
    
    % Add split data to the table
    aggregateTable.(chosenName) = goalItem_split(:,bin); 
    aggregateTable.(bestAltName) = bestAlt_split(:,bin); 
    aggregateTable.(interceptName) = intercepts(:,bin);    
    
    % Replace Nan with 0 for GLM
    aggregateTable.(chosenName)(isnan(aggregateTable.(chosenName)))=0; 
    aggregateTable.(bestAltName)(isnan(aggregateTable.(bestAltName)))=0;
    aggregateTable.(interceptName) = intercepts(:,bin);  


end

% For the illustrative analysis, include all the control regressors as statistical analysis (GLM3) across every trial (RT,
% switch/stay), but binning value by goal progress

regressors= {'norm_log_RT','norm_switchVsStay','chosen_bin1','chosen_bin2','chosen_bin3','chosen_bin4','chosen_bin5','chosen_bin6','bestAlt_bin1','bestAlt_bin2','bestAlt_bin3','bestAlt_bin4','bestAlt_bin5','bestAlt_bin6','intercept_bin1','intercept_bin2','intercept_bin3','intercept_bin4','intercept_bin5','intercept_bin6'};
%regressors= {'norm_log_RT','norm_switchVsStay','chosen_bin1','chosen_bin2','chosen_bin3','chosen_bin4','bestAlt_bin1','bestAlt_bin2','bestAlt_bin3','bestAlt_bin4','intercept_bin1','intercept_bin2','intercept_bin3','intercept_bin4'};


regTable = aggregateTable(:,ismember(aggregateTable.Properties.VariableNames, regressors)); 
nRegressors = numel(regressors); 
nModels = 1;
GLM_output = cell(nModels,1);

[GLM_output{1}.betas,GLM_output{1}.SE, GLM_output{1}.tStat] = run_tc_GLM_crossRun(choiceOnset, subjList, aggregateTable,  regressors,intercept, region_idx);
GLM_output{1}.name = 'all trials';


if saveModel
    output_folder = [neural_dat,'models/',modelName];
    save_model_output(GLM_output, choiceOnset, regressors, intercept, regions, subjList, output_folder);
end

