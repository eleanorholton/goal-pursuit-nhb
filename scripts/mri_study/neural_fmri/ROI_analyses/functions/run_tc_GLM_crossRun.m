function [betas,SE, tStat] = run_tc_GLM_crossRun(timec, subjList, aggregateTable,  regressors,intercept, analysis_regions, trial_condition_agg)
% runs for each subject, for each time point a separate regression with all
% regressors 

% Unlike the FSL whole-brain analysis, this script aggregates across separate runs before fitting. Only use to illustrative purposes (not statistics): specifically when binning value (to aid model fitting on sparse
% data) 


% If no index supplied, use full table
if ~exist('trial_condition_agg','var')
    trial_condition_agg = logical(ones(height(aggregateTable),1)); 
end
if ~exist('intercept','var')
    intercept = 0;
end

% Define number of regressors and time points 
nRegressors = numel(regressors);
if intercept 
    nRegressors_int = nRegressors + 1;
else
    nRegressors_int = nRegressors;
end
nregions = numel(analysis_regions); 
ntimep = size(timec.Region(1).epoched_timecourses{1}.all_runs,2);

 
% Preassign arrays 
betas = nan(length(subjList),nregions, ntimep,nRegressors_int); %subs, region, timepoints, regressors
tStat = nan(length(subjList),nregions, ntimep,nRegressors_int); %subs, region, timepoints, regressors
SE = nan(length(subjList),nregions, ntimep,nRegressors_int); %subs, region, timepoints, regressors

for reg = 1:nregions
    

    for p = 1:length(subjList)
        
        %subjInd = find(GLM.subjList==subjList(isub)); 
        
        timedat = timec.Region(reg).epoched_timecourses{p}.all_runs; 
        trialidx = timec.Region(reg).trial_indices{p}.all_runs; 

        % load subject specific data table 
        data_table = aggregateTable(aggregateTable.participant==subjList(p),:); % subject specific data table 
        idx_trials = trial_condition_agg(aggregateTable.participant==subjList(p)); % subject specific trial condition indices 
        idx_trials = idx_trials(trialidx); % use mri trial indices to crop the logical condition indices to fit quantity of mri data 
        nTrials = numel(trialidx); 

        % make regressor table
        regMat = zeros(nTrials,nRegressors); 
        for r = 1:nRegressors
            regs = eval(strcat('data_table.',regressors{r}));
            regMat(:,r) = regs(trialidx); 
            
        end


       [betas(p,reg,:,:),SE(p,reg,:,:), tStat(p,reg,:,:)] = fit_tc_GLM(regMat, timedat, idx_trials,intercept,nRegressors_int); 
       
    end

end
