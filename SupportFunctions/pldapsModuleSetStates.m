function p = pldapsModuleSetStates(p, sn, states)
% function p = pldapsSetModuleStates(p, sn, states)
% 
% Setup/update module requested states. Deals with unfortunate format
% of pldaps module innards:
%       p.trial.(sn).stateFunction.requestedStates == struct of logicals?!
% 
% INPUTS:
% [p]       Pldaps object
% [sn]      Module name; i.e.  p.trial.(sn)
% [states]  Cell of 'names' for pldaps states inwhich this module should be executed
%           e.g.  {'frameUpdate','trialSetup','trialCleanUpandSave','experimentPreOpenScreen','experimentPostOpenScreen'}
% 
% Recommend to use w/in main module code, during .experimentPreOpenScreen state.
% Previously this was done as an input to pldapsModule.m, but if done w/in
% main module code (e.g. function p = module(p,state,sn);), then changes to
% which states the module is used during only need to be made once,
% instead of w/in *every* experiment that uses the module.
% 
% 2020-11-11 TBC  Wrote it.
% 

% defaults
if nargin<2 || ~ischar(sn)
    error('Must provide module ''name'' as character string')
elseif nargin<3 || isempty(states)
    % special value of 'all' will execute module in every state available
    % (...may be computationally wasteful)
    states = 'all';
end

if iscell(states)
    % create struct of logicals for each state
    requestedStates = struct;
    for i = 1:length(states)
        requestedStates.(states{i}) = true;
    end
elseif ischar(states)
    % special 'all' case
    requestedStates = states;
end

% Apply "requestedStates" to module innards
p.trial.(sn).stateFunction.requestedStates = requestedStates;

end
    
