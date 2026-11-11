function save_model_output(GLM_output, timings, regressors, intercept, regions, participants, output_folder) 

full_model = {};
full_model.GLM_output = GLM_output; 
full_model.timings = timings;
full_model.regressors = regressors; 
full_model.intercept = intercept; 
full_model.regions = regions; 
full_model.subjIDs = participants; 
save(output_folder,'full_model')