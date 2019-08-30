function reboot(amount)
% pds.newEraSyringePump.reboot(amount)
%
% Make IOPort connection to New Era syringe pump following PLDAPS defaults
% Report previous pump history to command window (for posterity),
% Setup reward volume == [amount]       (default to 0.15 mL if no inputs provided)
% Zero out .volumeWithdrawn & .volumeGiven pumping volume history,
% Close connection.
% 
% [defVol] = optional input for default reward volume (in mL)
%            (...aka volume manual button/footpedal will deliver)
%
% 2019-04-11  TBC  Wrote it based on pds.newEraSyringePump.setup

%% initialize defaults
% ss.trial = pldaps.pldapsClassDefaultParameters;

if nargin<1 || isempty(amount)
    amount = 0.15; %   ss.behavior.reward.defaultAmount = amount;
end

%%
ss.newEraSyringePump.use = true;
ss.newEraSyringePump.allowNewDiameter = false;

% create a junk PLDAPS to load all default (incl. rig-specific!) settings
pp = pldaps('none',ss);

%% do the setup
% Use standard setup code (pds.newEraSyringePump.setup)
% so that any future updates there are already integrated!
pp = pds.newEraSyringePump.setup(pp);

%% Report prev volume history
[volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(pp);
fprintLineBreak;
fprintf('Previous:\n\tVolumeGiven = %4.1f,\t\tVolumeWithdrawn = %4.1f\n', volumeGiven, volumeWithdrawn);
fprintLineBreak;

%% Set reward volume & ENSURE DISPENSINGs
% Make readable shorthand
NES = pp.trial.newEraSyringePump;
newVol = sprintf('%*.*f', ceil(log10(amount)), min(3-ceil(log10(amount)),3),amount);
% ...from   pds.newEraSyringePump.give.m
IOPort('Write', NES.h, ['DIR INF', NES.commandSeparator, 'VOL ', newVol, NES.commandSeparator], 1);

%% Re-zero pumping volume history
IOPort('Write', NES.h, ['CLD INF', NES.commandSeparator, 'CLD WDR', NES.commandSeparator], 1);

%% Report happenings
[volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(pp);
fprintf('Current:\tReward Vol = %s mL\n\tVolumeGiven = %4.1f,\t\tVolumeWithdrawn = %4.1f\n', newVol, volumeGiven, volumeWithdrawn);
fprintLineBreak;

%% Close syringe pump connection
pds.newEraSyringePump.finish(pp)

end % main function
