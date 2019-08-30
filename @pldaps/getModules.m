function [moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = getModules(p, moduleType)
% function [moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = getModules(p, [moduleType])
% 
% Parse current module activity state, execution order, and trialStates during which they should be active.
% Return a list of module names, handles, states, and 
% This is called at the beginning of each trial.
%
% Module order will be determined by .stateFunction.order, running from -Inf : 0 : Inf.
%       Recommend using "order 0" for the pldapsDefaultTrialFunction module, then ordering other
%       modules before or after it in time.
%       *** NOTE: This is distinct from the ordering of trial states (.stateFunction.requestedStates)
%       becasue negative module order values are not ignored during the trial like state values are.
%       ...this is unfortunate, and potentially confusing.
% 
% [moduleType] is optional parameter for constraining the list of modules returned.
%       def:  moduleType = bitset(0,1); % only active modules
%       Operates as binary flags on each bit in moduleType, where bit:
%       1 == active state of module:        p.trial.(sn).use;           bitget(moduleType,1)
%       2 == marked for use by condMatrix:  p.trial.(sn).matrixModule;  bitget(moduleType,2)
%       3 == tracking module                p.trial.(sn).useAsEyepos;   bitget(moduleType,3)
%            (e.g. .eyelink, or .mouse, ...)
% 
%       EXAMPLES)
%       % Retrieve all active modules (classic/default mode)
%       getModules(p);
% 
%       % Retrieve [tracking module]:
%       getModules(p, bitset(0,3));     % also equivalent to:  getModules(p,3);
% 
%       % Retrieve only [active] [matrixModules]:
%       getModules(p, bitset(bitset(0,1), 2));
% 
%       ....
%       Pro-EXAMPLE) Retrieve modules containing a specific field & value:
%       getModules(p, {'thisField',thisValue; 'thatField',thatValue});
%
% See also:  pldaps.run
% 
% 2016-xx-xx  jk  Written for pldaps 4.2 by Jonas
% 2017-10-xx  tbc Added flag for module active state
% 2018-06-26  tbc Expanded with binary flag moduleType, for more control over module sub-selection & .condMatrix
% 2019-07-23  tbc Updated subselection options
% 

% Parse inputs & Initialize
[moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = deal([]);
doFieldCheck = 0;

if nargin<2 || isempty(moduleType)
    moduleType = bitset(0,1); % return only 'active' modules:  p.trial.(sn).use == true;
end


%% Find all modules in p.trial struct
moduleNames=fieldnames(p.trial);
moduleNames(cellfun(@(x) ~isstruct(p.trial.(x)),moduleNames))=[]; %remove non struct candidates

% Shortcircuit special cases (allow detection of core PLDAPS fields, like .mouse or .eyelink)
% --- return only 'active' module marked for use as eye position:  p.trial.(sn).use == true & p.trial.(sn).useAsEyepos == true;
if iscell(moduleType)
    % check for presence & value of a specified subfield
    for i = 1:size(moduleType,1)
        thisField = moduleType{i,1};
        thisVal = moduleType{i,2};
        moduleNames(cellfun(@(x) ~isfield(p.trial.(x), thisField), moduleNames)) = []; % check for presence
        moduleNames = moduleNames(cellfun(@(x) p.trial.(x).(thisField) == thisVal, moduleNames)); % matching value
    end
    return

elseif bitget(moduleType, 3)
    moduleNames = moduleNames(cellfun(@(x) ((isfield(p.trial.(x),'useAsEyepos') && p.trial.(x).useAsEyepos) && (isfield(p.trial.(x),'use') && p.trial.(x).use)), moduleNames));
    return
end

% Restrict to genuine modules (with executable .stateFunctions)
moduleNames(cellfun(@(x) ~isfield(p.trial.(x),'stateFunction'),moduleNames))=[]; %remove candidates without a stateFucntion specified

% Subselect modules based on moduleType
% --- return only 'matrixModules'
if bitget(moduleType, 2)
    moduleNames(cellfun(@(x) (~isfield(p.trial.(x).stateFunction,'matrixModule') || ~p.trial.(x).stateFunction.matrixModule ),moduleNames)) = [];
end

% --- return only 'active' modules:  p.trial.(sn).use == true;
if bitget(moduleType, 1)
    moduleNames(cellfun(@(x) (~isfield(p.trial.(x),'use') || ~p.trial.(x).use ),moduleNames)) = [];
end


%% Sort module execution by requested .stateFunction.order:
%      -Inf to 0 Default to Inf, (...Nan even after Inf, but don't do that)
% If no order specified, defaults to Inf.
moduleOrder = inf(size(moduleNames));
% if .order defined, retrieve it
hasOrder = cellfun(@(x) isfield(p.trial.(x).stateFunction,'order'), moduleNames);
moduleOrder(hasOrder) = cellfun(@(x) p.trial.(x).stateFunction.order, moduleNames(hasOrder));
[moduleOrder,so]=sort(moduleOrder);
moduleNames=moduleNames(so);


%% "acceptsLocationInput"
% Means the function accepts a 3rd [string] input specifying the p.trial structure fieldname
% where the relevant data & parameters are located.
%    e.g.  moduleFxnAbreviation = n = 'dots'; that locationInput[n] directs stateFunctions to look in  p.trial.(n).<whatever>
%
%   (...this should always be used. May only be here for backwards compatibility, but it
%       makes module creation more tedious/essoteric; consider removing. --TBC 2017-10)
moduleLocationInputs=cellfun(@(x)...
    (isfield(p.trial.(x).stateFunction,'modName') && ~isempty(p.trial.(x).stateFunction.modName))...
    || (isfield(p.trial.(x).stateFunction,'acceptsLocationInput') && p.trial.(x).stateFunction.acceptsLocationInput),...
    moduleNames);

moduleFunctionHandles=cellfun(@(x) str2func(p.trial.(x).stateFunction.name), moduleNames, 'UniformOutput', false);


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
                                            || strcmpi(p.trial.(y).stateFunction.requestedStates, 'all')...
                                            || (isfield(p.trial.(y).stateFunction.requestedStates,'all'))... && p.trial.(y).stateFunction.requestedStates.all)...
                                            || (isfield(p.trial.(y).stateFunction.requestedStates,x) && p.trial.(y).stateFunction.requestedStates.(x))),... % end @(y) customFxn
                                moduleNames)),... % end @(x) customFxn
                        availiableStates, 'UniformOutput', false);

% not totally clear what this special case is...backwards compatibility?
if isfield(p.trial.pldaps,'trialFunction') && ~isempty(p.trial.pldaps.trialFunction)
    moduleNames{end+1}='stimulus';
    moduleFunctionHandles{end+1}=str2func(p.trial.pldaps.trialFunction);
    for iState=1:length(moduleRequestedStates)
        moduleRequestedStates{iState}(end+1)=true;
    end
    moduleOrder(end+1)=NaN; %#ok<NASGU>
    moduleLocationInputs(end+1)=false;
end

% Format requested states to a struct of each available trialState, with logical flags for each module
% No, logical flags force use of a "find" call every time a module is called on every state (mmany times per frame!!)
% ...instead, do the find just once here
moduleRequestedStates=cellfun(@(x) find(x), moduleRequestedStates, 'UniformOutput', false);
    % NOTE: Something very strange happens here...
    %   Somewhere in the mergeToSingleStruct method of Params class,
    %   1-by-n fields get flipped into n-by-1 (and vice versa!@)
    %   So when this function is called it returns differently shaped inputs
    %   depending on whether its outside or inside the trialMasterFunction  (i.e. experimentPostOpenScreen vs. trialSetup)
    %   ...a proper fix to mergeToSingleStruct should be determined --TBC Oct. 2017
    %
    % The following line normalizes output, but does not fix the source.=
    %   (...only trial & error to find out why this line was here in first place...--TBC)
    moduleRequestedStates=cellfun(@(x) reshape(x,1,numel(x)), moduleRequestedStates, 'UniformOutput', false);

moduleRequestedStates=cell2struct(moduleRequestedStates,availiableStates);


end % end of function