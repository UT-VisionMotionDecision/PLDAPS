function p=calibrate(p)
%pds.eyelink.calibrate    start eyelink calibration routines
% p = pds.eyelink.calibrate(p)
%
% Run basic eyelink calibration sequence, using pldaps to present stimuli (via PTB)
% and send/receive communication from Eyelink.
% 
% [p]   Pldaps structure (should be currently running/paused)
%
% All relevant subfunctions located in pds.eyelink.cal
% 
% 12/12/2013 jly  adapted from EyelinkDoTrackerSetup.m
% 2017-11-02 TBC  Remove dependency on ".stimulus" field for fixdotW size
%                 Added .trialSetup of reward structures to prevent error (via pds.behavior.reward.trialSetup)
% 
       

if ~isfield(p.trial.eyelink, 'fixdotW')
    p.trial.eyelink.fixdotW = ceil(0.2 * p.trial.display.ppd);
end

% Prepare reward system
if isempty(p.trial.behavior.reward.timeReward)
    pds.behavior.reward.trialSetup(p);
end

commandwindow
if p.trial.sound.use
    Beeper
end
disp('*************************************')
disp('Beginning Eyelink Toolbox Calibration')
disp('*************************************')

disp('Checking if Eyelink is recording')


if Eyelink('CheckRecording')==0
    disp('Eyelink is currently recording');
else
    disp('Eyelink is not recording. Is it supposed to be');
end

mytext = 'Control Keys are:\rc\tcalibrate mode\rv\tvalidate\rd\tdrift correction\renter\tcamera setup\resc\texit\r'; 
fprintf(mytext)

% [nx, ny, textbounds] = DrawFormattedText(dv.disp.pter, mytext, dv.disp.ctr(1), dv.disp.ctr(2));


if nargin < 1
    error( 'USAGE: result=EyelinkDoTrackerSetup(el [,sendkey])' );
end
ListenChar(2)

% if Eyelink('CheckRecording')==0
%     fprintf('Eyelink is recording')

% Eyelink('Command', 'heuristic_filter = OFF');
Eyelink( 'StartSetup' );		% start setup mode
Eyelink( 'WaitForModeReady', p.trial.eyelink.setup.waitformodereadytime );  % time for mode change


key=1;
while key~= 0
    key=EyelinkGetKey(p.trial.eyelink.setup);		% dump old keys
end

stop=0;
while stop==0 && bitand(Eyelink( 'CurrentMode'), p.trial.eyelink.setup.IN_SETUP_MODE)
    
    i=Eyelink( 'CurrentMode');
    
    if ~Eyelink( 'IsConnected' ), stop=1; end;
    
    if bitand(i, p.trial.eyelink.setup.IN_TARGET_MODE)			% calibrate, validate, etc: show targets
        fprintf ('%s\n', 'dotrackersetup: in targetmodedisplay' );
        pds.eyelink.cal.targetModeDisplay(p);
    elseif bitand(i, p.trial.eyelink.setup.IN_IMAGE_MODE)		% display image until we're back
        fprintf ('%s\n', 'EyelinkDoTrackerSetup: in ''ImageModeDisplay''' );
        pds.eyelink.cal.clearDisplay(p);
        
    end
    
    [key, p.trial.eyelink.setup]=EyelinkGetKey(p.trial.eyelink.setup);		% getkey() HANDLE LOCAL KEY PRESS
    if 1 && key~=0 && key~=p.trial.eyelink.setup.JUNK_KEY    % print pressed key codes and chars
        fprintf('%d\t%s\n', key, char(key) );
    end
    
    switch key
        case p.trial.eyelink.setup.TERMINATE_KEY,				% breakout key code
            return;
        case { 0, p.trial.eyelink.setup.JUNK_KEY }          % No or uninterpretable key
        case p.trial.eyelink.setup.ESC_KEY,
            stop = 1;
            % add reward somehow
        otherwise, 		% Echo to tracker for remote control
            if p.trial.eyelink.setup.allowlocalcontrol==1
                Eyelink('SendKeyButton', double(key), 0, p.trial.eyelink.setup.KB_PRESS );
            end
    end
end % while IN_SETUP_MODE

pds.eyelink.cal.clearDisplay(p);	% exit_cal_display()
% dv = pds.eyelink.setup(dv);
Eyelink('StartRecording');
Eyelink( 'WaitForModeReady', p.trial.eyelink.setup.waitformodereadytime );  % time for mode change
    
ListenChar(0)
ShowCursor
return;
