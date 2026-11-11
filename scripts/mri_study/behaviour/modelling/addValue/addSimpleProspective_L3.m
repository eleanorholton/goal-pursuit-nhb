function [goal_item_value, best_alt_value, worst_alt_value, switch_value] = addSimpleProspective_L3(mag_goal_item, mag_best_alt, mag_worst_alt, net_contents, goal_size)

% Level 3 = progress to completion; 
% If negative alternative, set to offer
% If negative goal item, set to offer / net contents unless abs offer > net contents, in which case set to offer 
    
% Goal item
goal_item_value = mag_goal_item ./ (goal_size - net_contents); 

% Negatives become 0 
goal_item_value(mag_goal_item < 0) = mag_goal_item(mag_goal_item<0) ./ net_contents(mag_goal_item<0); 
goal_item_value(mag_goal_item < 0&abs(mag_goal_item)>net_contents) = mag_goal_item(mag_goal_item < 0&abs(mag_goal_item)>net_contents);

% Positives capped at 1 
goal_item_value(goal_item_value > 1) = 1; 


% Best alt
best_alt_value = mag_best_alt ./ goal_size; 

% Negatives set to offer 
best_alt_value(mag_best_alt < 0)  = mag_best_alt(mag_best_alt < 0); 
% Positives capped at 1 
best_alt_value(best_alt_value> 1) = 1; 

% Worst alt
worst_alt_value = mag_worst_alt ./ goal_size; 

% Negatives set to offer
worst_alt_value(mag_worst_alt < 0) = mag_worst_alt(mag_worst_alt < 0); 

% Positives capped at 1 
worst_alt_value(worst_alt_value> 1) = 1; 

switch_value = best_alt_value - goal_item_value; 
