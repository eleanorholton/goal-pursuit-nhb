%% Function to bin parameters by goal progress

% Inputs:
    % Aggregate table – processed data table including model value 
    % numSplits – number of bins to use
    % splitType – option to split data into equally sized bins (1) or
        %  according to the exact proportion of goal completed (2) 


function [goalItem_split, bestAlt_split, intercepts] = progressSplits(aggregateTable, numSplits, splitType, curr_goal_reg, alt_goal_reg)

% bin by proportion filled, ignoring first trials (where net is empty)
propData = aggregateTable.prop_filled; 
propData(aggregateTable.trial_number==1)=NaN; % don't include the first trials in the break-down by proportion filled
 

if splitType == 1 % Split the data into equally sized bins (rather than by proportion) 

    sortvals = sort(propData(~isnan(propData))); 
    binwidth = floor(length(sortvals)/numSplits);
    edges = sortvals([[1:numSplits-1]*binwidth])'; % if there are any remainder after dividing by split they automatically are added to the last bin 
    edges = [0 edges 1]; % indices should be between 0 and 1 (goal progress is a proportion)
    
    bin_category = discretize(propData,edges);

    
elseif splitType == 2 % Split the data into bins according to the proportion of the goal filled 
    
    edges = [[0:numSplits] * 1/numSplits];
    bin_category = discretize(propData,edges); 

end

% Assign value as a function of bin

goalItem_split = NaN(height(aggregateTable), numSplits);
bestAlt_split = NaN(height(aggregateTable),numSplits);
intercepts = zeros(height(aggregateTable),numSplits); 

for spl = 1:numSplits
    
    goalItem_split(bin_category==spl,spl) = curr_goal_reg(bin_category==spl); 
    bestAlt_split(bin_category==spl,spl) = alt_goal_reg(bin_category==spl); 
    intercepts(bin_category==spl,spl) = 1;
    
end
