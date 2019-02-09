function setReward(p, val)
% function moreReward(p, prct)
%
% Quick & dirty method to set juice reward level to [val]
% 	Default = 0.15
% 
% 2019-02-08  TBC  Wrote it.

if nargin < 2 || isempty(val)
    val = 0.15;
elseif val<=0
    % lower limit
    val = 0.01;
end

if nargin < 1
    % be scrappy
    evalin('caller', sprintf( 'p.trial.behavior.reward.defaultAmount = %f;', val));
    evalin('caller', sprintf( 'fprintf(''\\b\\t\\treward = %%2.3f\\n'', p.trial.behavior.reward.defaultAmount);'));
else
    % cleaner
    p.trial.behavior.reward.defaultAmount = val;
    fprintf('\b\t\treward = %2.3f\n', p.trial.behavior.reward.defaultAmount);
end

end % main function