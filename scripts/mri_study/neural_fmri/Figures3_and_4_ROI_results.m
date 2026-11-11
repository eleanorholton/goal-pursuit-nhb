%% ROI analyses results: VmPFC supports persistence during goal pursuit through selective attention 

% This script contains code to recreate the region of interest analysis plots and analyses from figures 3 and 4  

% Prerequisites
    % This script uses the GLMs fit to region-of-interest data created by  3_ROI_GLMs.m (found in scripts/mri_study/neural_fmri/ROI_analyses), and saved in data/mri_study/neural/models

% Author: Eleanor Holton, last edited 10/8/2023

%% setup  
base_folder = '/Users/eleanorholton/Dropbox/Oxford/PhD_thesis/ch_behaviour/goal_pursuit_scripts/'; 
addpath(genpath(base_folder)); 
model_folder = [base_folder, 'data/mri_study/neural/models/'];
subjList = 0:29;

%% Figure 3C (and supplementary figs.7d,e,f): timecourses of main regressors in ROIs at offer onset  

%modelname = 'whole_brain_analysis_GLM';
%modelname = 'whole_brain_analysis_GLM_persist_only2';
file_name = strcat(model_folder,modelname,'.mat'); 
load(file_name)

% Unpack data

GLM_output = full_model.GLM_output;
choiceOnset = full_model.timings;
ntimep = size(choiceOnset.Region(1).epoched_timecourses{1}.all_runs,2);   % number of timepoints in each epoch
regressors=full_model.regressors;
intercept = full_model.intercept; 
tmpcell = struct2cell(choiceOnset.Region);
regions = tmpcell(4,:); 
analysis_region_names = {'ACC','vmPFC','VS'};

firstcols = {'m','b','r','g'};
modelColours = {[0.3405767012687428, 0.1742560553633218, 0.5709342560553633], '#1E88E5', [0.8500 0.3250 0.0980],'g'};

%chosen_regressors = {'norm_prop_filled','norm_resid_sampler_goal_item','norm_resid_sampler_best_alt'};
chosen_regressors = {'norm_resid_sampler_goal_item','norm_resid_sampler_best_alt'};
intercept=1;

% Plot regressors 

for iregion = 1:numel(regions)
    
    region_idx = find(strcmp(regions,regions{iregion})); 
    figure('Position', [10 10 450 330]);
    
    for regressor = 1:numel(chosen_regressors)
       
       % get selected regressor
       regressor_idx = intercept+find(strcmp(regressors,chosen_regressors{regressor}));

       % plot mean activity 
       beta_weights = GLM_output{1}.betas; 
       standarderror = std(beta_weights(:,region_idx,:,regressor_idx))./sqrt(length(subjList)); 
       y = mean(beta_weights(:,region_idx,:,regressor_idx)); 
       x = [choiceOnset.window/ntimep:choiceOnset.window/ntimep:choiceOnset.window]; 

       % error bar
       s1 = shadedErrorBar(x,y,standarderror,'lineProps',{firstcols{regressor+1}},'transparent',1);
       s1.patch.FaceColor = modelColours{regressor+1};

       hold on; 
         
    end
    
    % labels and settings
    xlabel('time from offer onset (s)',fontsize=30); 
    ylabel(['effect on ',analysis_region_names{iregion},' BOLD ({\itβ})'],fontsize=40);% alternative title: beta coefficient
    xticks([0:2:choiceOnset.window])
    %yticks([-0.1,0,0.1])
    %ylim([-0.15,0.15])


    a = get(gca,'XTickLabel'); 
    set(gca,'XTickLabel',a,'fontsize',20)
    b = get(gca,'YTickLabel'); 
    set(gca,'YTickLabel',b,'fontsize',20)
    set(gca,'FontName','Verdana'); 
    yline(0);
    %title(analysis_region_names{iregion})
    
    f = gcf;
    exportgraphics(f,['timecourse_',analysis_region_names{iregion},'.png'],'Resolution',300)

    
end


% Save baseline vmPFC activity for further analysis 

vmpfc_index = find(strcmp('vmPFC_decision_peak',regions));

% get activity for vmpfc  
goal_progress_index = find(strcmp('norm_prop_filled',regressors))+intercept; 
vmpfc_baseline_goal_progress = full_model.GLM_output{1}.betas(:,vmpfc_index, 1, goal_progress_index); % timepoint 1 is baseline activity (i.e. moment of offer onset)  


baseline_table = array2table(vmpfc_baseline_goal_progress, 'VariableNames',{'baseline_vmpfc_gp'}); 
filename = [base_folder, '/data/mri_study/neural/baseline_vmpfc_activity.csv'];
writetable(baseline_table,filename)

%% %% Figure 3C (and supplementary figs.7d,e,f): timecourses of main regressors in ROIs at offer onset  

modelname = 'whole_brain_analysis_GLM_FIT3';
file_name = strcat(model_folder,modelname,'.mat'); 
load(file_name)

% Unpack data

GLM_output = full_model.GLM_output;
choiceOnset = full_model.timings;
ntimep = size(choiceOnset.Region(1).epoched_timecourses{1}.all_runs,2);   % number of timepoints in each epoch
regressors=full_model.regressors;
intercept = full_model.intercept; 
tmpcell = struct2cell(choiceOnset.Region);
regions = tmpcell(4,:); 
analysis_region_names = {'ACC','vmPFC','VS'};

firstcols = {'m','b','r','g'};
modelColours = {[0.3405767012687428, 0.1742560553633218, 0.5709342560553633], '#1E88E5', [0.8500 0.3250 0.0980],'g'};

chosen_regressors = {'norm_prop_filled'};
intercept=1;

% Plot regressors 

for iregion = 1:numel(regions)
    
    region_idx = find(strcmp(regions,regions{iregion})); 
    figure('Position', [10 10 450 330]);
    
    for regressor = 1:numel(chosen_regressors)
       
       % get selected regressor
       regressor_idx = intercept+find(strcmp(regressors,chosen_regressors{regressor}));

       % plot mean activity 
       beta_weights = GLM_output{1}.betas;%GLM_output{1}.betas(:,:,1:7,:);
       standarderror = std(beta_weights(:,region_idx,:,regressor_idx))./sqrt(length(subjList)); 
       y = mean(beta_weights(:,region_idx,:,regressor_idx)); 
       %x = [choiceOnset.window/ntimep:choiceOnset.window/ntimep:choiceOnset.window]; 
       x = 1:size(beta_weights,3);
       % error bar
       s1 = shadedErrorBar(x,y,standarderror,'lineProps',{firstcols{regressor}},'transparent',1);
       s1.patch.FaceColor = modelColours{regressor};

       hold on; 
         
    end
    
    % labels and settings
    xlabel('TR from offer onset (TR=1.23s)',fontsize=30); 
    ylabel(['effect on ',analysis_region_names{iregion},' BOLD ({\itβ})'],fontsize=40);% alternative title: beta coefficient
    xticks([1:1:size(beta_weights,3)])
    xticklabels(1.23*[-6:1:12])
    xline(7)
    yticks([-0.1,0,0.1])
    ylim([-0.15,0.15])


    a = get(gca,'XTickLabel'); 
    set(gca,'XTickLabel',a,'fontsize',20)
    b = get(gca,'YTickLabel'); 
    set(gca,'YTickLabel',b,'fontsize',20)
    set(gca,'FontName','Verdana'); 
    yline(0);
    %title(analysis_region_names{iregion})
    
    f = gcf;
    exportgraphics(f,['timecourse_',analysis_region_names{iregion},'.png'],'Resolution',300)

    
end


% Save baseline vmPFC activity for further analysis 

vmpfc_index = find(strcmp('vmPFC_decision_peak',regions));
acc_index = find(strcmp('ACC_decision_peak',regions));
striatum_index = find(strcmp('striatum_decision_peak',regions));
% get activity for vmpfc  
goal_progress_index = find(strcmp('norm_prop_filled',regressors))+intercept; 
vmpfc_baseline_goal_progress = full_model.GLM_output{1}.betas(:,vmpfc_index, :, goal_progress_index); % timepoint 1 is baseline activity (i.e. moment of offer onset)  
acc_baseline_goal_progress = full_model.GLM_output{1}.betas(:,acc_index, :, goal_progress_index); % timepoint 1 is baseline activity (i.e. moment of offer onset)  
ventral_striatum_baseline_goal_progress = full_model.GLM_output{1}.betas(:,striatum_index, :, goal_progress_index); % timepoint 1 is baseline activity (i.e. moment of offer onset)

vmpfcbaseline_table = array2table(squeeze(vmpfc_baseline_goal_progress));%, 'VariableNames',{'baseline_vmpfc_gp'}); 
filename = [base_folder, '/data/mri_study/neural/baseline_vmpfc_activity_fit.csv'];
writetable(vmpfcbaseline_table,filename)


accbaseline_table = array2table(squeeze(acc_baseline_goal_progress));%, 'VariableNames',{'baseline_vmpfc_gp'}); 
filename = [base_folder, '/data/mri_study/neural/baseline_acc_activity_fit.csv'];
writetable(accbaseline_table,filename)


VSbaseline_table = array2table(squeeze(ventral_striatum_baseline_goal_progress));%, 'VariableNames',{'baseline_vmpfc_gp'}); 
filename = [base_folder, '/data/mri_study/neural/baseline_vs_activity_fit.csv'];
writetable(VSbaseline_table,filename)

%% Value sensitivity analysis (interaction between goal progress and value difference)   
% Does the impact of value disappear in striatum, acc, and vmpfc? 

% Import model
modelname = 'value_difference_interaction_analysis';
file_name = strcat(model_folder,modelname,'.mat'); 
load(file_name)

% Unpack data
GLM_output = full_model.GLM_output;
choiceOnset = full_model.timings;
ntimep = size(choiceOnset.Region(1).epoched_timecourses{1}.all_runs,2);   % number of timepoints in each epoch
regressors=full_model.regressors;
intercept = full_model.intercept; 
tmpcell = struct2cell(choiceOnset.Region);
regions = tmpcell(4,:); 

% Set up haemodynamic response function parameters (to match wholebrain analysis) 
sigma1=2.449; my1=6; % first gamma, for main response
sigma2=4; my2=16;  % second gamma, for undershoot
alpha1=my1^2/sigma1^2; % for main peak
beta1=sigma1^2/my1;
alpha2=my2^2/sigma2^2; % for post-undershoot
beta2=sigma2^2/my2;
res=choiceOnset.TR./choiceOnset.upsample;
ratio=6; % second to first gamma ratio
t = [choiceOnset.window/ntimep:choiceOnset.window/ntimep:choiceOnset.window];
hrf = gampdf(t,alpha1,beta1) - gampdf(t,alpha2,beta2)/ratio;
[~, hrfMax] = max(hrf);

% index of interaction regressor
intercept = 1; 
gp_regressor_idx = intercept+find(strcmp(regressors,'norm_prop_filled'));

% Loop over subjects and regions
multHRF = NaN(numel(subjList),numel(regions));

figure; hold on;
for iregion = 1:numel(regions)
    

    %region_idx = find(strcmp(regions,regions{iregion}));
    
    for p = 1:numel(subjList)
        
        % multiply the HRF function by the time course betas for the
        % regressor 
        multHRF(p,iregion) = sum(squeeze(GLM_output{1}.betas(p,iregion,:,gp_regressor_idx)).*hrf'); 
        scatter(iregion,multHRF(p,iregion))
    end
    
    bar(iregion, mean(multHRF(:,iregion)))

    
end
xticklabels(regions)
%% Value sensitivity analysis (interaction between goal progress and value difference)   
% Does the impact of value disappear in striatum, acc, and vmpfc? 

% Import model
modelname = 'value_difference_interaction_analysis';
file_name = strcat(model_folder,modelname,'.mat'); 
load(file_name)

% Unpack data
GLM_output = full_model.GLM_output;
choiceOnset = full_model.timings;
ntimep = size(choiceOnset.Region(1).epoched_timecourses{1}.all_runs,2);   % number of timepoints in each epoch
regressors=full_model.regressors;
intercept = full_model.intercept; 
tmpcell = struct2cell(choiceOnset.Region);
regions = tmpcell(4,:); 

% Set up haemodynamic response function parameters (to match wholebrain analysis) 
sigma1=2.449; my1=6; % first gamma, for main response
sigma2=4; my2=16;  % second gamma, for undershoot
alpha1=my1^2/sigma1^2; % for main peak
beta1=sigma1^2/my1;
alpha2=my2^2/sigma2^2; % for post-undershoot
beta2=sigma2^2/my2;
res=choiceOnset.TR./choiceOnset.upsample;
ratio=6; % second to first gamma ratio
t = [choiceOnset.window/ntimep:choiceOnset.window/ntimep:choiceOnset.window];
hrf = gampdf(t,alpha1,beta1) - gampdf(t,alpha2,beta2)/ratio;
[~, hrfMax] = max(hrf);

% index of interaction regressor
intercept = 1; 
interaction_regressor_idx = intercept+find(strcmp(regressors,'value_x_goal_progress'));

% Loop over subjects and regions
multHRF = NaN(numel(subjList),numel(regions));


for iregion = 1:numel(regions)

    region_idx = find(strcmp(regions,regions{iregion}));
    
    for p = 1:numel(subjList)
        
        % multiply the HRF function by the time course betas for the
        % regressor 
        multHRF(p,iregion) = sum(squeeze(GLM_output{1}.betas(p,region_idx,:,interaction_regressor_idx)).*hrf'); 
    
    end
    
end

sensitivity_effect_table = array2table(multHRF,'variableNames',{regions{:}}); 

% Sign-rank tail (non normally distributed) 
% abandonment value (best alt-curr goal) has negative effect on vmPFC and striatum so disappearance = increase in activity over time (right-tailed test) 
[hval_striatum, sigtest_striatum, striatum_res] = signrank(sensitivity_effect_table.striatum_decision_peak,0,'tail','right'); 
[hval_vmpfc, sigtest_vmpfc, vmpfc_res] = signrank(sensitivity_effect_table.vmPFC_decision_peak,0,'tail','right'); 

% abandonment value has positive effect on ACC so disappearance = decrease in activity over time (left-tailed test) 
[hval_acc, sigtest_acc, acc_res] = signrank(sensitivity_effect_table.ACC_decision_peak,0,'tail','left'); 


%% Statistic for asymmetry in alternative vs. current goal value representations as a function of goal progress (only on striatum, post-hoc to determine whether single source of value is driving loss of sensitivity)

% Import model
modelname = 'value_component_interaction_analysis';
file_name = strcat(model_folder,modelname,'.mat'); 
load(file_name)

% Unpack data
GLM_output = full_model.GLM_output;
choiceOnset = full_model.timings;
ntimep = size(choiceOnset.Region(1).epoched_timecourses{1}.all_runs,2);   % number of timepoints in each epoch
regressors=full_model.regressors;
intercept = full_model.intercept; 
tmpcell = struct2cell(choiceOnset.Region);
regions = tmpcell(4,:); 

% index of interaction regressor
intercept = 1; 
curr_interaction_regressor_idx = intercept+find(strcmp(regressors,'curr_value_x_progress'));
alt_interaction_regressor_idx = intercept+find(strcmp(regressors,'alt_value_x_progress'));

% Loop over subjects and regions
multHRF = NaN(numel(subjList),numel(regions));


for iregion = 1:numel(regions)

    region_idx = find(strcmp(regions,regions{iregion}));
    
    for p = 1:numel(subjList)
        
        % multiply the HRF function by the time course betas for the
        % regressor 
        
        % current goal value
        multHRF(p,iregion) = sum(squeeze(GLM_output{1}.betas(p,region_idx,:,curr_interaction_regressor_idx)).*hrf'); 
        
        % alt goal value
        multHRF(p,iregion + numel(regions)) = sum(squeeze(GLM_output{1}.betas(p,region_idx,:,alt_interaction_regressor_idx)).*hrf'); 
    
    end
    
end

tablenames = [strcat(regions,{'_curr', '_curr','_curr'}), strcat(regions,{'_alt', '_alt','_alt'})]; 
sensitivity_effect_table = array2table(multHRF,'variableNames',{tablenames{:}}); 

[hval_striatum_curr, sigtest_striatum_curr, striatum_res_curr] = signrank(sensitivity_effect_table.striatum_decision_peak_curr, 0,'tail','left'); % reduction in impact current value in striatum = decreasing signal (left tail)
[hval_striatum_alt, sigtest_striatum_alt, striatum_res_alt] = signrank(sensitivity_effect_table.striatum_decision_peak_alt, 0,'tail','right'); % reduction in impact of alt value in striatum = increasing (right tail)

[hval_vmpfc_curr, sigtest_vmpfc_curr, vmpfc_res_curr] = signrank(sensitivity_effect_table.vmPFC_decision_peak_curr, 0,'tail','left'); % reduction in impact current value in striatum = decreasing signal (left tail)
[hval_vmpfc_alt, vmpfc_striatum_alt, vmpfc_res_alt] = signrank(sensitivity_effect_table.vmPFC_decision_peak_alt, 0,'tail','right'); % reduction in impact of alt value in striatum = increasing (right tail)

% reverse tail in ACC due to opposite impact of value acc regions 
[hval_acc_curr, sigtest_acc_curr, acc_res_curr] = signrank(sensitivity_effect_table.ACC_decision_peak_curr, 0,'tail','right'); % reduction in impact current value in striatum = decreasing signal (left tail)
[hval_acc_alt, sigtest_acc_alt, acc_res_alt] = signrank(sensitivity_effect_table.ACC_decision_peak_alt, 0,'tail','left'); % reduction in impact of alt value in striatum = increasing (right tail)

%% Figure 4b. Illustration of asymmetry in value representations as a function of goal progress (binning data) 

modelname = 'illustration_interaction_binned';
file_name = strcat(model_folder,modelname,'.mat'); 
load(file_name)

% Unpack data

GLM_output = full_model.GLM_output;
choiceOnset = full_model.timings;
ntimep = size(choiceOnset.Region(1).epoched_timecourses{1}.all_runs,2);   % number of timepoints in each epoch
regressors=full_model.regressors;
intercept = full_model.intercept; 
tmpcell = struct2cell(choiceOnset.Region);
regions = tmpcell(4,:); 
participants = full_model.subjIDs; 

val_type_colours = {[30, 136, 229]/256,[230, 97, 0]/256};

% Plot binned value separately 
chosen_regressors = {'chosen_bin1','chosen_bin2','chosen_bin3','chosen_bin4','chosen_bin5','chosen_bin6'};
best_alt_regressors = {'bestAlt_bin1','bestAlt_bin2','bestAlt_bin3','bestAlt_bin4','bestAlt_bin5','bestAlt_bin6'};

all_regressors = [chosen_regressors, best_alt_regressors]; 
region_names = {'ACC','vmPFC','striatal'}; 

multHRF = [];

% 
count=0; 
for reg = 1:numel(regions)
    figure('Position',[10 10 380 480]); hold on;
    selectRegion = regions{reg}; 
    region_idx =find(strcmp(regions,selectRegion));
    count = count+1; 
 

goal_regs = NaN(numel(chosen_regressors),1);

for regressor = 1:numel(chosen_regressors)
    
    regressor_idx = intercept+find(strcmp(regressors,chosen_regressors{regressor}));


    for p = 1:numel(participants)
        
        % Multiply haemodynamic response function by time course beta
        % weights to get aggregate effect at participant level 
        multHRF(p,regressor) = sum(squeeze(GLM_output{1}.betas(p,region_idx,:,regressor_idx)).*hrf');
        
    end
    
    
    goal_regs(regressor) = (mean(multHRF(:,regressor))); 
    
  
    errorbar(regressor, (mean(multHRF(:,regressor))), std(multHRF(:,regressor))/sqrt(size(multHRF(:,regressor),1)),'Color',val_type_colours{1},'LineWidth',3,'HandleVisibility','off');hold on;
    swarmchart(repmat(regressor,size(multHRF(:,regressor),1),1),(multHRF(:,regressor)),'filled','MarkerFaceColor',val_type_colours{1},'MarkerEdgeColor',val_type_colours{1},'MarkerFaceAlpha',0.1,'MarkerEdgeAlpha',0.1,'HandleVisibility','off');    

end

plot(1:numel(goal_regs), goal_regs,'Color',val_type_colours{1},'LineWidth',3); 
alt_regs = NaN(numel(best_alt_regressors),1);

% alternative regr
for regressor = 1:numel(best_alt_regressors)
    
    regressor_idx = intercept+find(strcmp(regressors,best_alt_regressors{regressor}));


    for p = 1:numel(participants)
        multHRF(p,regressor) = sum(squeeze(GLM_output{1}.betas(p,region_idx,:,regressor_idx)).*hrf'); 
    end
    
    
    alt_regs(regressor) = (mean(multHRF(:,regressor))); 
    errorbar(regressor, (mean(multHRF(:,regressor))), std(multHRF(:,regressor))/sqrt(size(multHRF(:,regressor),1)),'Color',val_type_colours{2},'LineWidth',3,'HandleVisibility','off');
    
    swarmchart(repmat(regressor,size(multHRF(:,regressor),1),1),(multHRF(:,regressor)),'filled','MarkerFaceColor',val_type_colours{2},'MarkerEdgeColor',val_type_colours{2},'MarkerFaceAlpha',0.1,'MarkerEdgeAlpha',0.1,'HandleVisibility','off');    

end

plot(1:numel(alt_regs),alt_regs,'Color',val_type_colours{2},'LineWidth',3);
ylabel(['effect on ',region_names{reg},' BOLD'],'fontsize',30)
xlabel('goal progress (%)','fontsize',30)

xticks([0.5,3.5,6.5]);
xlim([0,7])
xticklabels({'0','50','100'}); 

yticks([-6:2:6]); 
ylim([-3,4]);

yline(0,'LineWidth',3)
% lgd = legend({'current goal value','alternative goal value'},'fontsize',20);
% lgd.FontSize = 30;

set(gca,'FontSize',30,'fontname','Verdana')

f = gcf;
exportgraphics(f,['modulation_',region_names{reg},'.png'],'Resolution',300)

end
