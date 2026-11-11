
function [probabilities, choice] = softmax(values, temp) 

probabilities = exp(values.*temp)./sum(exp(values.*temp)); 
    
% generate choice

  g = rand; 

if g < probabilities(1)
    choice = 1;
elseif g < probabilities(1) + probabilities(2)
    choice = 2; 
else
    choice = 3;
end