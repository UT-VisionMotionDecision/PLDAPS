function [modules, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = getModules(p)
% function [modules, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = getModules(p)
% 
% Parse currently active modules, execution order, and trialStates during which they should be active.
% This is called at the beginning of each trial.
%
% Module order will be determined by .stateFunction.order, running from -Inf : 0 : Inf.
% NOTE: This is distinct from the ordering of trial states (.stateFunction.requestedStates)
%       becasue negative module order values are not ignored during the trial like state values are.
%       ...this is unfortunate, and potentially confusing.
%       Recommend only using positive values to order your modules to be more 'future proof' [hint].
%       --TBC 2017-10

%% Find all modules in p.trial struct
modules=fieldnames(p.trial);
modules(cellfun(@(x) ~isstruct(p.trial.(x)),modules))=[]; %remove non struct candidates
modules(cellfun(@(x) ~isfield(p.trial.(x),'stateFunction'),modules))=[]; %remove candidates without a stateFucntion specified
modules(cellfun(@(x) (~isfield(p.trial.(x),'use') || ~p.trial.(x).use ),modules))=[]; %remove modules not activated


%% Sort module execution by requested .stateFunction.order:
%      -Inf to 0 Default to Inf, (...Nan even after Inf, but don't do that)
% If no order specified, defaults to Inf.
moduleOrder = inf(size(modules));
% if .order defined, retrieve it
hasOrder = cellfun(@(x) isfield(p.trial.(x).stateFunction,'order'), modules);
moduleOrder(hasOrder) = cellfun(@(x) p.trial.(x).stateFunction.order, modules(hasOrder));
[moduleOrder,so]=sort(moduleOrder);
modules=modules(so);


%% "acceptsLocationInput"
% Means the function accepts a 3rd [string] input specifying the p.trial structure fieldname
% where the relevant data & parameters are located.
%    e.g.  moduleFxnAbreviation = n = 'dots'; that locationInput[n] directs stateFunctions to look in  p.trial.(n).<whatever>
%
%   (...this should always be used. May only be here for backwards compatibility, but it
%       makes module creation more tedious/essoteric; consider removing. --TBC 2017-10)
moduleLocationInputs=cellfun(@(x) (isfield(p.trial.(x).stateFunction,'acceptsLocationInput') && p.trial.(x).stateFunction.acceptsLocationInput),modules);

moduleFunctionHandles=cellfun(@(x) str2func(p.trial.(x).stateFunction.name), modules, 'UniformOutput', false);


%% Limit module execution to certain trialStates
% Cross reference all trial states in use, with those specifically requested by the module
% If none specified, make module active for all states.
availiableStates=fieldnames(p.trial.pldaps.trialStates);
%a little too long, ok, so if requestedStates is not defined, or .all
%is true, we will call it for all states. Otherwise it will only call
%the ones defined and true. --jk 2016(?)
moduleRequestedStates = cellfun(@(x)...
                                (cellfun(@(y)...
                                            (~isfield(p.trial.(y).stateFunction,'requestedStates')...
                                            || (isfield(p.trial.(y).stateFunction.requestedStates,'all') && p.trial.(y).stateFunction.requestedStates.all)...
                                            || (isfield(p.trial.(y).stateFunction.requestedStates,x)...
                                            && p.trial.(y).stateFunction.requestedStates.(x))),... % end @(y) customFxn
                                modules)),... % end @(x) customFxn
                        availiableStates, 'UniformOutput', false);

% not totally clear what this special case is...backwards compatibility?
if isfield(p.trial.pldaps,'trialFunction') && ~isempty(p.trial.pldaps.trialFunction)
    modules{end+1}='stimulus';
    moduleFunctionHandles{end+1}=str2func(p.trial.pldaps.trialFunction);
    for iState=1:length(moduleRequestedStates)
        moduleRequestedStates{iState}(end+1)=true;
    end
    moduleOrder(end+1)=NaN;
    moduleLocationInputs(end+1)=false;
end

% Format requested states to a struct of each available trialState, with logical flags for each module
moduleRequestedStates=cellfun(@(x) reshape(x,1,numel(x)), moduleRequestedStates, 'UniformOutput', false);
moduleRequestedStates=cell2struct(moduleRequestedStates,availiableStates);


end % end of function