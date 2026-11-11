%% Calculates number of trials needed to fill net when starting with option, using an additional simple prospective model to consider whether you might switch in the future 

% Input
    % mags = 3 x nTrials array of future magnitudes for all the options 
    % previousChoice = current net item
    % goalSize = size of net 
    % netContents = accumulated magnitude
% Output
    % completion_time = 3x1 array number of trials to fill the net 
    % switches = 3x1 array: number of future switch trials starting with each option 
    % choice_chain = 3x1 cell of arrays of future choices when starting with each of the options
    
function [completion_times, switches, choice_chain] = calculateVal_consider_switches(mags, previousChoice, goalSize, netContents)

completion_times =  repmat(size(mags,1),1,3); % Default – if the net isn't filled in the trials, set completion time as number of trials
switches = NaN(1,3);
choice_chain = cell(1,3); 

for option = 1:3
     
    accumVal = NaN(size(mags,1), 1); 
    choice = NaN(size(mags,1),1); 
    switchTrials = zeros(size(mags,1),1); 
    prosp_val = zeros(size(mags,2), 3); 
    
    % Define content at t=1 when starting with each option 
     
    if option==previousChoice
        accumVal(1) = netContents + mags(1,option);
    else
        accumVal(1) = mags(1,option);  
    end
    
    complete = 0; 
    t=0;
    
    while complete < 1 
        
        
        t=t+1; 
        
        if t == 1
            
            choice(t) = option; 
            
        else
            
            % Use the SIMPLE PROSPECTIVE MODEL to evaluate whether or not model is likely to switch at future time points for the simulated magnitudes
            
             prosp_val(t,:) = - (goalSize ./ mags(t,:)); % to find value of alternative options: divide net size by magnitude of each option (made negative)
             prosp_val(t,choice(t-1)) = - ((goalSize - accumVal(t-1)) / mags(t,choice(t-1))); % Overwrite value of chosen item to include net contents
             prosp_val(t,mags(t,:)<0) = -1000; % If the magnitude of an item is negative, the time-to-completion estimate is tricky, because technically it is 'infinite'. Here we set these items to value -1000 so they are very unlikely to be chosen but they don't mess up our regressions/softmax.  
             prosp_val(t,prosp_val(t,:)>-1) = -1; % Capping: Values greater than -1 are capped at -1 because it can never take less than 1 trial to complete 

             % Make choice (without softmax to avoid incurring more noise) 
             [~, choice(t)] = max(prosp_val(t,:));

            % Track switches and calculate accumulated value 
            if choice(t) ~= choice(t-1) % for switch trials, net contents does not carry over 
                   switchTrials(t) = 1;
                   accumVal(t) = mags(t,choice(t));
            else
                   accumVal(t) = accumVal(t-1) + mags(t,choice(t)); 
            end
        
        end
        
        % Cannot have negative net contents
        accumVal(t) = max(accumVal(t),0); 
        
         % Check whether net has been completed
        
        if accumVal(t)>=goalSize
            complete=1;
            completion_times(option) = t; 
         end
             
         if t+1 > size(mags,1) % If net is never filled in simulated future, end loop  
             complete=1;
         end

    end
    
    choice = rmmissing(choice); 
    choice_chain{option} = choice; 
    switches(option) = sum(switchTrials); 
    
         
end
        