%% Voxel-wise regression with permutation based cluster correction  

% Note in order for the fsl commands to work, MATLAB needs to be launched
% from terminal e.g. /Applications/MATLAB_R2021a.app/bin/matlab &

% Script function
% 1) Fits persistence biases across patient population
% 2) Runs voxel-wise regression analysis predicting bias using voxel damage in each voxel 
% 3) Runs 1000 iterations of permutation analysis predicting scrambled biases using voxel damage (n.b. runtime takes approx 60 hours)
% 4) Uses False discovery rate to find cluster correction threshold
% 5) Outputs cluster corrected mask of empirical t-stats


clear all; 
close all; 

% set FSL environment
setenv('FSLDIR','/usr/local/fs');  % location of FSL folder
setenv('FSLOUTPUTTYPE', 'NIFTI_GZ'); % type of output 


%% Variables and data

home_folder = '';
addpath(genpath(home_folder)); 

data_path = [home_folder,'data/lesion_patient_study/'];
cluster_pathway = [data_path, 'voxelwise_regression/']; 

% Load lesion maps
load([data_path, 'lesion_maps/full_lesion_map_dat.mat']); 
mapids=[files_ordered{:,4}]; 

% Load  behavioural data
dataFolder = data_path;
patient_ids =  [303 304 305 306 310 315 317 319 325 327 330 333 339 344 545 345 346 347 348 349 350 352 407]; 

aggregate_patient_data=[];
for p = 1:numel(patient_ids)
    id = patient_ids(p); 
    patient_table = readtable([dataFolder, 'behaviour/all_patient_data/',num2str(id),'.csv']);

    aggregate_patient_data = [aggregate_patient_data; patient_table]; 
    clear patient_table; 
end

% set t-statistic threshold
t_threshold = 2.3; 

% template of information needed to save nifti images
threeD_info = niftiinfo([data_path, 'voxelwise_regression/example_metadata.nii.gz']); % get sample metadata for saving nifti images

%% 1. Fit persistence bias across patient population

agg_patient_IDs = unique(aggregate_patient_data.participant); % all patient IDs
n_patients = numel(agg_patient_IDs); 
aggregate_patient_data.sampler_value_switching = aggregate_patient_data.sampler_best_alt - aggregate_patient_data.sampler_goal_item; % add switch value 

persistence_table = NaN(n_patients,2); % ID, persistence bias
all_patient_mdls = cell(n_patients,1); 

for p = 1:numel(agg_patient_IDs)
    
    persistence_table(p,1) = agg_patient_IDs(p); % first column ID 
    
    % fit logistic regression to each patient 
    all_patient_mdls{p} = fitglm(aggregate_patient_data(aggregate_patient_data.participant==agg_patient_IDs(p),:), 'switch_trial ~  sampler_value_switching','Distribution','binomial');
    
    % Extract individual model coefficients 
    intercept = all_patient_mdls{p}.Coefficients.Estimate(find(strcmp(all_patient_mdls{p}.CoefficientNames,'(Intercept)')));             
    beta = all_patient_mdls{p}.Coefficients.Estimate(find(strcmp(all_patient_mdls{p}.CoefficientNames,'sampler_value_switching'))); 
                
    % Get persistence bias (equivalence point=-intercept/beta) 
    persistence_table(p,2) = -intercept / beta; 
    

end

%% Map behavioural data to lesion maps

% Find indices of intersection between lesion maps and behavioural IDs 
[shared_vals, map_idx] = intersect(mapids, persistence_table(:,1),'stable');
lesion_behavior_matrix = NaN(numel(shared_vals), 3);

for p = 1:numel(shared_vals)
    
    pID=shared_vals(p);
    
    lesion_behavior_matrix(p,1) = pID; % participant ID
    lesion_behavior_matrix(p,2) = map_idx(p); % index of participant in lesion map data 
    lesion_behavior_matrix(p,3) = persistence_table(find(persistence_table(:,1)==pID),2); % persistence bias for corresponding ID

end

sorted_table = array2table(lesion_behavior_matrix,'VariableNames',{'participant','map_idx','bias'}); 

%% 2) Voxel-wise regression analysis predicting bias using voxel damage in each voxel (n.b. skip to 4 to avoid re-running these analyses)

mapsize=size(complete_maps);
voxelwise_betas = NaN(mapsize(1:3)); % x,y,z size of map (across patients) 
voxelwise_tstats =  NaN(mapsize(1:3));
voxelwise_pvals =  NaN(mapsize(1:3));

for x=1:mapsize(1)
    
    for y=1:mapsize(2)
        
        for z=1:mapsize(3)
            
            full_voxels = squeeze(complete_maps(x,y,z,:)); % get all lesion data at particular voxel
            voxels = double(full_voxels(sorted_table.map_idx)); % extract patients tested to match behavioural data 

            if sum(voxels)==0 % If no patients are damaged in voxel, do not run analysis 

                voxelwise_betas(x,y,z) = 0; 
                voxelwise_tstats(x,y,z) = 0; 
            
            else
                
                % Add voxels to table             
                itr_table = sorted_table;
                itr_table.voxel_damage = voxels;
                
                % Fit glm
                mdl = fitglm(itr_table, 'bias ~ voxel_damage'); 
                
                % Save model coefficients 
                voxelwise_betas(x,y,z) = mdl.Coefficients.Estimate(find(strcmp(mdl.CoefficientNames,'voxel_damage'))); 
                voxelwise_tstats(x,y,z) = mdl.Coefficients.tStat(find(strcmp(mdl.CoefficientNames,'voxel_damage'))); 
                voxelwise_pvals(x,y,z) = mdl.Coefficients.pValue(find(strcmp(mdl.CoefficientNames,'voxel_damage'))); 
                
            end
            
        end
    end
    
    disp(['finished x=',num2str(x),' out of ',num2str(mapsize(1))]); % track progress 
    
end 

% save coefficients
results_path = [cluster_pathway, 'originals/'];

% Save betas 
betas_fname = [results_path,'voxelwise_betas.nii']; 
voxelwise_betas_info = threeD_info; 
voxelwise_betas_info.Filename = betas_fname;
voxelwise_betas_info.Datatype = class(voxelwise_betas); 
niftiwrite(voxelwise_betas,betas_fname,voxelwise_betas_info,'Compressed',true); 

% Save tstats
tstats_fname = [results_path,'voxelwise_tstats.nii']; 
voxelwise_tstats_info = threeD_info; 
voxelwise_tstats_info.Filename = tstats_fname;
voxelwise_tstats_info.Datatype = class(voxelwise_tstats); 
niftiwrite(voxelwise_tstats,tstats_fname,voxelwise_tstats_info,'Compressed',true); 

% Save neg tstats
voxelwise_neg_tstats = -(voxelwise_tstats); 
neg_tstats_fname = [results_path,'voxelwise_neg_tstats.nii']; 
voxelwise_neg_tstats_info = threeD_info; 
voxelwise_neg_tstats_info.Filename = neg_tstats_fname;
voxelwise_neg_tstats_info.Datatype = class(voxelwise_neg_tstats); 
niftiwrite(voxelwise_neg_tstats,neg_tstats_fname,voxelwise_neg_tstats_info,'Compressed',true); 

% Save abs tstats
voxelwise_abs_tstats = abs(voxelwise_tstats); 
abs_tstats_fname = [results_path,'voxelwise_abs_tstats.nii']; 
voxelwise_abs_tstats_info = threeD_info; 
voxelwise_abs_tstats_info.Filename = abs_tstats_fname;
voxelwise_abs_tstats_info.Datatype = class(voxelwise_neg_tstats); 
niftiwrite(voxelwise_abs_tstats,abs_tstats_fname,voxelwise_abs_tstats_info,'Compressed',true); 

% Save pvals
voxelwise_pvals(isnan(voxelwise_pvals))=NaN; 
pvals_fname = [results_path,'voxelwise_pvals.nii']; 
voxelwise_pvals_info = threeD_info; 
voxelwise_pvals_info.Filename = pvals_fname;
voxelwise_pvals_info.Datatype = class(voxelwise_pvals); 
niftiwrite(voxelwise_pvals,pvals_fname,voxelwise_pvals_info,'Compressed',true); 



%% 3. Permutation test to find cluster threshold size

%Permute order over each iteration, and run same analysis

n_itr = 1000; 
mapsize=size(complete_maps);

for i = 1:n_itr
    
    disp(['starting iteration ',num2str(i)]); 
    
    % shuffle the biases at the start of each iteration to permutute regression 
    shuffled_biases =sorted_table.bias(randperm(length(sorted_table.bias))); 
    
    voxelwise_betas = NaN(mapsize(1:3)); % x,y,z size of map (across patients) 
    voxelwise_tstats =  NaN(mapsize(1:3));
    voxelwise_pvals =  NaN(mapsize(1:3));

    for x=1:mapsize(1)

        for y=1:mapsize(2)

            for z=1:mapsize(3)

                full_voxels = squeeze(complete_maps(x,y,z,:)); % get all lesion data at particular voxel
                voxels = double(full_voxels(sorted_table.map_idx)); % extract patients tested to match behavioural data 

                if sum(voxels)==0 % If no patients are damaged in voxel, do not run analysis 

                    voxelwise_betas(x,y,z) = 0; 
                    voxelwise_tstats(x,y,z) = 0; 

                else

                    % Add voxels to table             
                    itr_table = sorted_table;
                    itr_table.voxel_damage = voxels;
                    itr_table.shuffled_bias = shuffled_biases; 

                    % Fit glm
                    mdl = fitglm(itr_table, 'shuffled_bias ~ voxel_damage'); 


                    % Save model coefficients 
                    voxelwise_betas(x,y,z) = mdl.Coefficients.Estimate(find(strcmp(mdl.CoefficientNames,'voxel_damage'))); 
                    voxelwise_tstats(x,y,z) = mdl.Coefficients.tStat(find(strcmp(mdl.CoefficientNames,'voxel_damage'))); 
                    voxelwise_pvals(x,y,z) = mdl.Coefficients.pValue(find(strcmp(mdl.CoefficientNames,'voxel_damage'))); 

                end

            end
        end

    end 

    % Save betas 
    betas_fname = [cluster_pathway,'permutations/regression_coefficients/voxelwise_betas_',num2str(i),'nii']; 
    voxelwise_betas_info = threeD_info; 
    voxelwise_betas_info.Filename = betas_fname;
    voxelwise_betas_info.Datatype = class(voxelwise_betas); 
    niftiwrite(voxelwise_betas,betas_fname,voxelwise_betas_info,'Compressed',true); 

    % Save tstats
    tstats_fname = [cluster_pathway,'permutations/regression_coefficients/voxelwise_tstats_',num2str(i),'nii']; 
    voxelwise_tstats_info = threeD_info; 
    voxelwise_tstats_info.Filename = tstats_fname;
    voxelwise_tstats_info.Datatype = class(voxelwise_tstats); 
    niftiwrite(voxelwise_tstats,tstats_fname,voxelwise_tstats_info,'Compressed',true); 

    % Save neg tstats
    voxelwise_neg_tstats = -(voxelwise_tstats); 
    neg_tstats_fname = [cluster_pathway,'permutations/regression_coefficients/voxelwise_neg_tstats_',num2str(i),'nii']; 
    voxelwise_neg_tstats_info = threeD_info; 
    voxelwise_neg_tstats_info.Filename = neg_tstats_fname;
    voxelwise_neg_tstats_info.Datatype = class(voxelwise_neg_tstats); 
    niftiwrite(voxelwise_neg_tstats,neg_tstats_fname,voxelwise_neg_tstats_info,'Compressed',true); 

    % Save abs tstats
    voxelwise_abs_tstats = abs(voxelwise_tstats); 
    abs_tstats_fname = [cluster_pathway,'permutations/regression_coefficients/voxelwise_abs_tstats_',num2str(i),'nii']; 
    voxelwise_abs_tstats_info = threeD_info; 
    voxelwise_abs_tstats_info.Filename = abs_tstats_fname;
    voxelwise_abs_tstats_info.Datatype = class(voxelwise_neg_tstats); 
    niftiwrite(voxelwise_abs_tstats,abs_tstats_fname,voxelwise_abs_tstats_info,'Compressed',true); 

    % Save pvals
    voxelwise_pvals(isnan(voxelwise_pvals))=NaN; 
    pvals_fname = [cluster_pathway,'permutations/regression_coefficients/voxelwise_pvals_',num2str(i),'nii']; 
    voxelwise_pvals_info = threeD_info; 
    voxelwise_pvals_info.Filename = pvals_fname;
    voxelwise_pvals_info.Datatype = class(voxelwise_pvals); 
    niftiwrite(voxelwise_pvals,pvals_fname,voxelwise_pvals_info,'Compressed',true); 


end

%% 4. Estimate cluster threshold size for FDR 

n_itr=1000;

% save clusters across iterations 
all_cluster_sizes = [];
largest_cluster_stats = NaN(n_itr,1); 
largest_cluster_sizes = NaN(n_itr,1); 

no_cluster_count=0; % count iterations where no cluster was found
for i = 1:n_itr
    
    % Do cluster thresholding on tstatistic map 
    tstats_fname = [cluster_pathway,'permutations/regression_coefficients/voxelwise_neg_tstats_',num2str(i),'.nii.gz']; 
    cluster_fname = [cluster_pathway,'permutations/clusters/clustered_mask',num2str(i)]; 
    cmdStr = ['cluster -i ' tstats_fname ' -t ' num2str(t_threshold) ' -o ' cluster_fname];
    system(cmdStr) ;
    
    % read in tstatistic and cluster maps
    sim_data_tstatistics = niftiread(tstats_fname); 
    sim_data_clusters = niftiread([cluster_fname,'.nii.gz']);
    
    % find unique clusters 
    unique_clusters = unique(sim_data_clusters); 
    unique_clusters=unique_clusters(unique_clusters>0); % remove 0 (0 indicates no cluster data)
    
    % save all cluster sizes, largest cluster size, and sum of tstatistics
    % in clusters
    cluster_statistics = NaN(numel(unique_clusters),1);  
    cluster_sizes = NaN(numel(unique_clusters),1); 
    
    for uc = 1:numel(unique_clusters)
        
        cluster_statistics(uc) = sum(sim_data_tstatistics(sim_data_clusters==unique_clusters(uc))); % sum of tstats in cluster
        cluster_sizes(uc) = numel(sim_data_tstatistics(sim_data_clusters==unique_clusters(uc))); % number of voxels in cluster
        all_cluster_sizes = [all_cluster_sizes, cluster_sizes(uc)]; % Add cluster size to array of all cluster sizes
        
    end
    
    % other info (not  necessary for fdr) 
    % If no clusters found, set max cluster size to 0 
    if (isempty(cluster_sizes))
        
        cluster_sizes= [0];
        cluster_statistics = [0];
        no_cluster_count = no_cluster_count + 1; 
    end
     
    largest_cluster_stats(i) = max(cluster_statistics); % max over cluster statistics in iteration
    largest_cluster_sizes(i) = max(cluster_sizes); % max over cluster sizes in iteration

end

false_discover_rate_clusters = all_cluster_sizes; % sizes of all false positives 
save([cluster_pathway,'permutations/clusters/FDR.mat'],'false_discover_rate_clusters');

%% False discovery rate
load([cluster_pathway,'permutations/clusters/FDR.mat']);

% find 95 percentile of cluster sizes found in simulations
ordered_cluster_size = sort(false_discover_rate_clusters);
FDR_threshold = ordered_cluster_size(round(numel(ordered_cluster_size)*.95)); 

%% 5) Find whole brain clusters and apply cluster-correction using FDR

% Get clusters from empirical analysis
empirical_tstats_path = [cluster_pathway,'originals/', 'voxelwise_neg_tstats.nii.gz']; % negative statistics: where damage predicts decrease in persistence bias
whole_brain_clusters_path = [cluster_pathway,'originals/', 'neg_tstat_clusters_wholebrain.nii.gz']; % negative statistics: where damage predicts decrease in persistence bias
whole_brain_clusters_path_txt = [cluster_pathway,'originals/', 'cluster_info.txt']; % negative statistics: where damage predicts decrease in persistence bias

cmdStr = ['cluster -i ' empirical_tstats_path ' -t ' num2str(t_threshold) ' -o ' whole_brain_clusters_path ' > ' whole_brain_clusters_path_txt];
system(cmdStr) ;

% import empirical clusters
empirical_clusters = readtable([cluster_pathway,'originals/', 'cluster_info.txt']);
sig_cluster = empirical_clusters(empirical_clusters.Voxels>FDR_threshold,:); % empirical clusters over FDR threshold are significant

% Threshold clusters
cluster_no = sig_cluster.ClusterIndex; 
cluster_corrected_path = [cluster_pathway, 'cluster_corrected_tstats'];
cmdStr = ['fslmaths -dt int ',whole_brain_clusters_path,' -thr ',num2str(cluster_no),' -uthr ',num2str(cluster_no),' ',cluster_corrected_path];
system(cmdStr) ;

%% Plot distribution over clusters

% histogram of size of false positive clusters
figure; histogram(false_discover_rate_clusters,50); hold on; 
xlabel('cluster size','fontsize',18); ylabel('freq','fontsize',18); 

a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'FontName','Verdana')
b = get(gca,'YTickLabel');
set(gca,'YTickLabel',b,'FontName','Verdana')

% plot FDR threshold
plot([FDR_threshold,FDR_threshold],[0,400],'r','linewidth',2.5); 
ylim([0,400])

% plot empirical cluster size
plot([sig_cluster.Voxels ,sig_cluster.Voxels ],[0,400],'b','linewidth',2.5,'linestyle','--'); % for

