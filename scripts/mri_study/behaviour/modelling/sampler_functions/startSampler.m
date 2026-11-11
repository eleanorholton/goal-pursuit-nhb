%% Simulates sampler model decisions for a single block 

function [valueMeans, decisionSequence,switchTrials, netContents, estimatedProximity,  valueUncertainty, fullDistributions, future_switch_estimate] = startSampler(magnitudes, goalSize, nItr, var, cut_off,  p_jumpUp, p_jumpLo, xmax, xmin, jumpHi, jumpLo, temperature,useSoftMax,startingVal,bias,consider_future_switching)

if ~exist('bias','var')
bias = 0;
end
 

nTrials = length(magnitudes); 

decisionSequence = zeros(1,nTrials);
estimatedProximity = zeros(1,nTrials); 
netContents = zeros(1,nTrials); 
switchTrials = zeros(1,nTrials); 

future_switch_estimate = cell(1,nTrials);
fullDistributions = cell(1,nTrials); 

valueMeans = zeros(nTrials, 3); 
valueUncertainty = zeros(nTrials, 3); 


netContents(1)=0; 
previousChoice = NaN; 

t=0; 
finish = 0; 

while finish < 1
    
    t = t+1; 
    
    [decisionSequence(t), netContents(t+1), estimatedProximity(t), switchTrials(t), valueMeans(t,:), valueUncertainty(t,:), fullDistributions{t},future_switch_estimate{t}] = evaluateOptions(magnitudes(t,:), netContents(t), previousChoice, goalSize, nItr, var, cut_off, p_jumpUp, p_jumpLo, xmax, xmin, jumpHi, jumpLo, temperature, t,startingVal,bias,useSoftMax,consider_future_switching);
            
    % Net contents cannot drop below 0 
    netContents(t+1) = max(netContents(t+1),0); 

   
    if netContents(t+1) >= goalSize  % Determine if net is complete
            
            completionTime = t;
            finish = 1; 
            
    else % Update accumulated value and previous choice
      
        previousChoice = decisionSequence(t); 
    end
        
     if t==length(magnitudes)
            completionTime = inf; 
            finish = 1;
     end
      
    
end

if completionTime ~=inf
    
    decisionSequence = decisionSequence(1:completionTime);
    estimatedProximity = estimatedProximity(1:completionTime);
    netContents = netContents(1:completionTime);
    switchTrials = switchTrials(1:completionTime); 
    
    valueMeans = valueMeans(1:completionTime, :); 
    valueUncertainty = valueUncertainty(1:completionTime, :); 
    fullDistributions = fullDistributions(1:completionTime);
    future_switch_estimate = future_switch_estimate(1:completionTime); 
    
end
    