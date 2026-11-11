function [goal_item_value, best_alt_value, worst_alt_value, switch_value] = addSimpleProspective_L1(mag_goal_item, mag_best_alt, mag_worst_alt, net_contents, goal_size)

% Level 1 = progress to completion unless negative, in which case 0 

% Goal item
goal_item_value = mag_goal_item ./ (goal_size - net_contents); 
% Negatives become 0 
goal_item_value(mag_goal_item < 0) = 0;  
% Positives capped at 1 
goal_item_value(goal_item_value>1) = 1; 


% Best alt
best_alt_value = mag_best_alt ./ goal_size; 

% Negatives become 0 
best_alt_value(mag_best_alt<0) = 0; 
% Positives capped at 1 
best_alt_value(best_alt_value>1) = 1; 

% Worst alt
worst_alt_value = mag_worst_alt ./ goal_size; 

% Negatives become 0 
worst_alt_value(mag_worst_alt<0) =0; 
% Positives capped at 1 
worst_alt_value(worst_alt_value>1) = 1; 


switch_value = best_alt_value - goal_item_value; 
