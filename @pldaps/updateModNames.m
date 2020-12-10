function updateModNames(p)
% function pldaps.updateModNames(p)
% 
% Update list of active and/or particular module names in the pldaps structure.
% 
% TODO: Allow user defined function handle that will update any additional modules they
%       determine to be important/worthy of tracking.
%       e.g.  p.trial.pldaps.modNames.mySpecialThing = getModules(p, {'thisField',thisValue; 'thatField',thatValue});
% 
% See also: pldaps.getModules, pldaps.run
% 
% 2019-07-26  TBC  Wrote it.
% 

% Establish list of all module names    (see help pldaps.getModules)
p.trial.pldaps.modNames.all             = getModules(p, 0);
p.trial.pldaps.modNames.matrixModule    = getModules(p, bitset(0,2));
p.trial.pldaps.modNames.tracker         = getModules(p, bitset(0,3));

% assign module names for certain special cases
if isfield(p.trial.pldaps.modNames, 'behavior')
    p.trial.behavior.modName = p.trial.pldaps.modNames.behavior{1};
end