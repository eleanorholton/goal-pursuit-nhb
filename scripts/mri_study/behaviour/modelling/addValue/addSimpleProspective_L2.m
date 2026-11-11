function [goal_item_value, best_alt_value, worst_alt_value, switch_value] = addSimpleProspective_L2(mag_goal_item, mag_best_alt, mag_worst_alt, net_contents, goal_size)

% Level 2 = progress to completion; 
%if negative alternative, set to -1; 
%if negative goal item, do offer / net contents but cap at -1 (ie if abs offer > net contents)
    
% Goal item
goal_item_value = mag_goal_item ./ (goal_size - net_contents); 
% Treat negatives 
goal_item_value(mag_goal_item<0) = mag_goal_item(mag_goal_item<0) ./ net_contents(mag_goal_item<0); 
goal_item_value(goal_item_value<-1) = -1; 

% Positives capped at 1 
goal_item_value(goal_item_value>1) = 1; 


% Best alt
best_alt_value = mag_best_alt ./ goal_size; 

% Negatives become -1
best_alt_value(mag_best_alt<0) = -1; 

% Positives capped at 1 
best_alt_value(best_alt_value>1) = 1; 

% Worst alt
worst_alt_value = mag_worst_alt ./ goal_size; 

% Negatives become -1
worst_alt_value(mag_worst_alt<0) = -1; 

% Positives capped at 1 
worst_alt_value(worst_alt_value>1) = 1; 

switch_value = best_alt_value - goal_item_value; 