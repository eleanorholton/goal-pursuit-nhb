%% Generates single item gaussian walk with occasional jumps up and down 
% Input
    % initialVal = starting value of walk 
    % var = variance on the gaussian walk 
    % xmin/xmax = range of values the walk is limited to 
    % p_jumpUp, p_jumpLo = probability an item will jump up or down
    % jumpHi/jumpLo = jump function 
    % nTrials = n walk steps generated
    % trialPosition = which 'trial' the walk starts on (matters for jump
    % function e.g. jump is higher later on in a block)
    % startingMean = mean of starting value distribution (matters for jump function i.e. jumps are defined by initial starting value rather than current value)
% Output
    % mags: vector of item magnitudes nTrials long
    % jumpTrials: logical index of jumps (1=jump)

function [mags,jumpTrials] = walk_with_jumps(initialVal, var, p_jumpUp, p_jumpLo, xmax, xmin, jumpHi,jumpLo, nTrials, trialPosition, startingMean)

if isnan(trialPosition) % if generating an entire vector of magnitudes for the schedule (rather than simulating a path from a magnitude within the walk), then just start walk at trial 1 
    trialPosition=1; end 

mags = [initialVal zeros(1, nTrials-1)];
jumpTrials = zeros(1,nTrials); 

for t = 2:nTrials
    
     if rand < (p_jumpUp + p_jumpLo) % option magnitude jumps
                        
            jumpTrials(t)= 1;
            
            if rand < p_jumpUp / (p_jumpUp + p_jumpLo) % Determine direction of jump 
                
                mags(t) = jumpHi(startingMean, trialPosition-1+t);
            
            else
                mags(t) = jumpLo(startingMean, trialPosition-1+t);
  
            end
                 
     else  % random walk
         
         mags(t) = mags(t-1) + randn*var; 
         
     end
     
       
      % Cap magnitudes at limits
      
      if mags(t)>xmax
          mags(t)=xmax;
      elseif mags(t)<xmin
          mags(t)=xmin;
      end  
      
end