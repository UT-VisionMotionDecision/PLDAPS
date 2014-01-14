function dv=pdsEyelinkCalibrate(dv)
% dv = pdsEyelinkCalibrate(dv)

% USAGE: result=EyelinkDoTrackerSetup(el [, sendkey])
%
%		dv.el: Eyelink default values

% 12/12/2013 jly adapted from EyelinkDoTrackerSetup.m
commandwindow
Beeper
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
% if we have the new callback code, we call it.
% if ~isempty(dv.el.callback)
%     if Eyelink('IsConnected') ~= dv.el.notconnected
%         if ~isempty(dv.el.window)
%             rect=Screen(dv.el.window,'Rect');
%             % make sure we use the correct screen coordinates
%             Eyelink('Command', 'screen_pixel_coords = %d %d %d %d',rect(1),rect(2),rect(3)-1,rect(4)-1);
%         end
%     else
%         return
%     end
%     result = Eyelink( 'StartSetup', 1 );
%
%     return;
% end
% else we continue with the old version

% if Eyelink('CheckRecording')==0
%     fprintf('Eyelink is recording')

Eyelink('Command', 'heuristic_filter = ON');
Eyelink( 'StartSetup' );		% start setup mode
Eyelink( 'WaitForModeReady', dv.el.waitformodereadytime );  % time for mode change


key=1;
while key~= 0
    key=EyelinkGetKey(dv.el);		% dump old keys
end

stop=0;
while stop==0 && bitand(Eyelink( 'CurrentMode'), dv.el.IN_SETUP_MODE)
    
    i=Eyelink( 'CurrentMode');
    
    if ~Eyelink( 'IsConnected' ), stop=1; end;
    
    if bitand(i, dv.el.IN_TARGET_MODE)			% calibrate, validate, etc: show targets
        fprintf ('%s\n', 'dotrackersetup: in targetmodedisplay' );
        pdsEyelinkTargetModeDisplay(dv);
    elseif bitand(i, dv.el.IN_IMAGE_MODE)		% display image until we're back
        fprintf ('%s\n', 'EyelinkDoTrackerSetup: in ''ImageModeDisplay''' );
        pdsEyelinkClearCalDisplay(dv);	% setup_cal_display()
        
    end
    
    [key, dv.el]=pdsEyelinkGetKey(dv.el);		% getkey() HANDLE LOCAL KEY PRESS
    if 1 && key~=0 && key~=dv.el.JUNK_KEY    % print pressed key codes and chars
        fprintf('%d\t%s\n', key, char(key) );
    end
    
    switch key
        case dv.el.TERMINATE_KEY,				% breakout key code
            return;
        case { 0, dv.el.JUNK_KEY }          % No or uninterpretable key
        case dv.el.ESC_KEY,
            stop = 1;
            % add reward somehow
        otherwise, 		% Echo to tracker for remote control
            if dv.el.allowlocalcontrol==1
                Eyelink('SendKeyButton', double(key), 0, dv.el.KB_PRESS );
            end
    end
end % while IN_SETUP_MODE

pdsEyelinkClearCalDisplay(dv);	% exit_cal_display()
dv = pdsEyelinkSetup(dv);
ListenChar(0)
ShowCursor
return;
