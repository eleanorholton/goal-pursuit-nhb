%% Calculates number of trials needed to fill net for each option, *not* considering whether you might switch in the future

% Input
    % mags = 3 x nTrials array of future magnitudes for all the options 
    % previousChoice = current net item
    % goalSize = size of net 
    % netContents = accumulated magnitude
% Output
    % completion_time = number of trials to fill the net 
    
function [completion_times] = calculateVal_simple(mags, previousChoice, goalSize, netContents)
completion_times =  repmat(size(mags,1),1,3); % Default – if the net isn't filled in the trials, set completion time as number of trials

for option = 1:3
     
    accumVal = mags(:,option); 
    
    % Define content at t=1 when starting with each option 
     
    if option==previousChoice
        accumVal(1) = netContents + mags(1,option);
    else
        accumVal(1) = mags(1,option);  
    end
    
    for k=2:size(mags,1)
        accumVal(k) = max(accumVal(k-1)+accumVal(k), 0); % the contents cannot drop below 0
    end
    
    final = find(accumVal>=goalSize,1); 
    
    % If net is not completed within available trials, leave the
    % completion_time at nTrials
    
    if ~isempty(final)
        completion_times(option) = final;
    end
    
end
