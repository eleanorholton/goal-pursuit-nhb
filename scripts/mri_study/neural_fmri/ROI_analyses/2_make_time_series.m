
%% Script to make time series file over region of interest (txt file)

% Note in order for the fsl commands to work, MATLAB needs to be launched
% from terminal e.g. /Applications/MATLAB_R2021a.app/bin/matlab &

%% set FSL environment
setenv('FSLDIR','/usr/local/fs');  % location of FSL folder
setenv('FSLOUTPUTTYPE', 'NIFTI_GZ'); % type of output 

base_folder = '';

%% Define rois
ROI_names = {''};;
subjList = [0:29]; 

%% Define files

for i_ROI = 1:numel(ROI_names)
    
    ROI_NAME = ROI_names{i_ROI}; % name of mask to run time series on 

    dataFolder = strcat([base_folder, 'data/mri_study/neural/preprocessed_fmri_data/']); 
    mask_directory = 'data/mri_study/neural/ROI/';

    maskFolder = strcat([mask_directory,'ROI/',ROI_NAME]);

    standard2highres_warps_folder = [mask_directory,'standard2highres_warps'];
    if ~isfolder(strrep(standard2highres_warps_folder,'\',''))
        mkdir(strrep(standard2highres_warps_folder,'\',''));
    end

    individual_masks_folder = [maskFolder, '/individual_masks'];
    if ~isfolder(strrep(individual_masks_folder,'\',''))
        mkdir(strrep(individual_masks_folder,'\',''));
    end

    timeCourse_files_folder = [maskFolder, '/timeCourse_files'];
    if ~isfolder(strrep(timeCourse_files_folder,'\',''))
        mkdir(strrep(timeCourse_files_folder,'\',''));
    end 

    standard_space_mask = [maskFolder, '/',ROI_NAME,'_sphere.nii.gz'];
    %% Loop over subjects and runs
    
    all_files = dir(dataFolder); 
    filenames = {all_files.name}; 

    for s = 1:numel(subjList) 

        ID = subjList(s); 
        
        if s<10
            ID_full = strcat(['sub_0',num2str(ID)]); 
        else
            ID_full = strcat(['sub_',num2str(ID)]); 
            
        end
        
        nRuns = sum( ~cellfun(@isempty, strfind(filenames, ID_full)) )
        
        for run = 1:nRuns


            % Individual registration data path
            subPath = strcat([dataFolder,'preproc_',ID_full,'_run', num2str(run), '.feat']);

            % Denoised functional file 
            func_denoised = [subPath '/filtered_func_data.nii.gz'];

            % Registration files 
            highres2standard_warp = [subPath '/reg/highres2standard_warp.nii.gz'];
            highres = [subPath '/reg/highres.nii.gz'];
            example_func = [subPath '/reg/example_func.nii.gz'];
            highres2example_func = [subPath '/reg/highres2example_func.mat'];

            % Name of warp file to go from standard space to subject space
            standard2highres_warp = [standard2highres_warps_folder, '/sub_0' num2str(ID) '_run' num2str(run) '_standard2highres_warp.nii.gz']; 

            % Create standard —> subject space warp file if it doesn't already exist
            if ~isfile(standard2highres_warp)
                cmdStr1 = ['invwarp -w ' highres2standard_warp ' -o ' standard2highres_warp ' -r ' highres];
                system(cmdStr1)
            end

            individual_mask_file = [individual_masks_folder '/sub_0' num2str(ID) '_run' num2str(run)]; 

            % Use the new registration file to create the individual subject mask 
            cmdStr2 = ['applywarp -i ' standard_space_mask ' -r ' example_func ' -o ' individual_mask_file ' -w ' standard2highres_warp ' --postmat=' highres2example_func];
            system(cmdStr2) 

            time_course_file = [timeCourse_files_folder '/sub_0' num2str(ID) '_run' num2str(run)];

            % Use the mask to create a textfile of the extracted (and averaged) timecourse from the ROI
            cmdStr4 = ['fslmeants -i ' func_denoised ' -m ' individual_mask_file ' -o ' time_course_file '.txt'];
            system(cmdStr4)
            
        end


    end

end
