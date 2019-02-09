function moreReward(p, prct)
% function moreReward(p, prct)
%
% Quick & dirty method to increase juice reward level by [prct]%
% 	Default = 10%
% 
% 2019-02-08  TBC  Wrote it.
if nargin < 2 || isempty(prct)
    prct = 1.1;
else
    prct = 1 + prct/100;
end
% lower limit
prct(prct<=0) = .01;

if nargin < 1
    % be scrappy
    evalin('caller', sprintf( 'p.trial.behavior.reward.defaultAmount = p.trial.behavior.reward.defaultAmount * %f;', prct));
    evalin('caller', sprintf( 'fprintf(''\\b\\t\\treward = %%2.3f\\n'', p.trial.behavior.reward.defaultAmount);'));
else
    % cleaner
    p.trial.behavior.reward.defaultAmount = p.trial.behavior.reward.defaultAmount * prct;
    fprintf('\b\t\treward = %2.3f\n', p.trial.behavior.reward.defaultAmount);
end

end % main function