%% Evaluates the options on a single trial according to sampler model

% Input
    % currMags – 3x1 array of offers
    % accumulatedValue – current net contents
    % netItem – current net item
    % goalSize – target net quantity 
    % nItr – number of simulated future option magnitudes 
    % The following input come from estimates of the generation model: 
        % var - variance on the random walk 
        % p_jumpUp/p_jumpLo - probability an item will jump up or down
        % xmax/xmin – range of values the walk is limited to
        % jumpHi/jumpLo – jump function 
        % startingMean – original starting mean of distribution 
    % cut_off – number of trials to simulate before ending 
    % trialPosition – number of trials into the block (affects jump function) 
    % bias – number added to the value of the chosen option 
    % useSoftMax – whether to use softmax in addition to noise included in iterative sampling 
    % temperature – softmax decision temperature  
    % consider_future_switching – % Option to either consider the possibility of switching in the future within the value of choosing each option, or compute the value of staying with the option until the net is filled. 
    


% Output
    % modelOutput: nBlocks x 1 cell array of structures with 4 fields: 
        % choice – 1, 2, or 3 
        % accumulatedValue – accumulated value after choice (net contents) 
        % estimatedProximity – integer: estimate number of trials to completion (*after choice*)  
        % switchTrial – 0/1 is the chosen item different from the previous choice
        % samplerValue – 3 x 1 array: mean estimate of completion time across iterations, negated (so smaller completion times = more attractive)
        % valueCertainty – 3 x 1 array: standard deviation across the iterations of completion times of each option 
        % fullDistributions – 3 x nIterations: all the simulated completion times for each option in each iteration
        % future_switch_estimate - number of predicted future switches 
  

function [choice, accumulatedValue, estimatedProximity, switchTrial,samplerValue, valueCertainty, full_value_matrix,future_switch_estimates] =  evaluateOptions(currMags, accumulatedValue, netItem, goalSize, nItr, var, cut_off, p_jumpUp, p_jumpLo, xmax, xmin, jumpHi, jumpLo, temperature, trialPosition,startingMean,bias,useSoftMax, consider_future_switching)

    if ~exist('bias','var')
        
        bias = 0;
        
    end

    % Calculate sampler value of the three options 

    full_value_matrix = zeros(nItr, 3); 
    track_switches = zeros(nItr, 3); 

    for i = 1:nItr

         % Simulate future magnitudes for each option 

         mags = zeros(cut_off, 3);

         for option = 1:3 

           mags(:,option) = walk_with_jumps(currMags(option), var, p_jumpUp, p_jumpLo, xmax, xmin, jumpHi,jumpLo, cut_off,trialPosition,startingMean); 

         end

         % Calculate net completion time with the simulated magnitudes (when choosing each option)

          if consider_future_switching
              [simulationValues, switches] = calculateVal_consider_switches(mags, netItem, goalSize, accumulatedValue); 
              track_switches(i,:) = switches; 
          else
              simulationValues = calculateVal_simple(mags, netItem, goalSize, accumulatedValue); 
          end

         full_value_matrix(i,:) = simulationValues; 


    end

    % Make choice 
    
    samplerValue = -mean(full_value_matrix,1); % sampler value for each option = the mean number of trials until the net is completed (made negative so small completion times are attractive) 
    switchMeans = mean(track_switches,1); 
    
    if ~isnan(netItem) % add the bias if it's not the first trial 
        
        samplerValue(netItem) = samplerValue(netItem) + bias; 
        
    end

    if useSoftMax
        
        [~,choice] = softmax(samplerValue,temperature);
        
    else
        
        [~,choice] = max(samplerValue);
    end

    % Determine switch
    
    if netItem~=choice && ~isnan(netItem)
        
        switchTrial = 1;
        accumulatedValue = currMags(choice);
        
    else
        
        switchTrial =0;
        accumulatedValue = currMags(choice) + accumulatedValue;
        
    end
    
    % Cannot have negative accumulated value 
    accumulatedValue = max(accumulatedValue, 0); 

    % What is estimated number of times the model will switch from the
    % current decision in future? 
    future_switch_estimates = switchMeans; 

    % Model's estimate of proximity to block end
    estimatedProximity = -samplerValue(choice) - 1; 

    % 'certainty' of trials to completion for each option
    % (standard deviation across simulations) 
    valueCertainty = std(full_value_matrix,1); 
 
