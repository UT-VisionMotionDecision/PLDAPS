function result=targetModeDisplay(p)
% function result = pds.eyelink.cal.targetModeDisplay(p)
% set eyelink into target mode
%
% 
%
% result=targetModeDisplay(p)
%
% History
% 15-05-01	fwc created first version
% 22-05-01	fwc	little debugging
% 02-06-01	fwc removed use of global el, as suggested by John Palmer.
% 22-06-06  fwc OSX-ed
% 2014      jk  changed to work with version 4.1


result=-1; % initialize return argument
if nargin < 1
	error( 'USAGE: result = pds.eyelink.cal.targetModeDisplay(p)' );
end

% % % targetvisible = 0;	% target currently drawn
% % % targetrect=[0 0 0 0];
% % % 
% % % tx=p.trial.eyelink.setup.MISSING;
% % % ty=p.trial.eyelink.setup.MISSING;
% % % 
% % % otx=p.trial.eyelink.setup.MISSING;    % current target position
% % % oty=p.trial.eyelink.setup.MISSING;

% Get current target position from Eyelink
[~, tx, ty]= Eyelink( 'TargetCheck');
xy = [tx;ty];
fprintf('Target XY: [%4.2f, %4.2f]\t', tx, ty);

pds.eyelink.cal.clearDisplay(p);	% setup_cal_display()

key=1;
while key~= 0
	[key, p.trial.eyelink.setup]=EyelinkGetKey(p.trial.eyelink.setup);		% dump old keys
end

% LOOP WHILE WE ARE DISPLAYING TARGETS
while bitand(Eyelink('CurrentMode'), p.trial.eyelink.setup.IN_TARGET_MODE)

    if Eyelink( 'IsConnected' )==p.trial.eyelink.setup.notconnected
        result=-1;
        return;
    end

%     fprintf('mode: %s\n', dec2bin(Eyelink('CurrentMode')))
	[key, p.trial.eyelink.setup]=EyelinkGetKey(p.trial.eyelink.setup);		% getkey() HANDLE LOCAL KEY PRESS

	switch key 
		case p.trial.eyelink.setup.TERMINATE_KEY       % breakout key code
			pds.eyelink.cal.clearDisplay(p);
			result=p.trial.eyelink.setup.TERMINATE_KEY;
			return;
            
		case p.trial.eyelink.setup.SPACE_BAR	         		% 32: accept fixation
            if p.trial.eyelink.setup.allowlocaltrigger==1
				Eyelink( 'AcceptTrigger');
            end
            pds.behavior.reward.give(p);
			break;
            
		case { 0,  p.trial.eyelink.setup.JUNK_KEY	}	% No key
            
		case p.trial.eyelink.setup.ESC_KEY
            if Eyelink('IsConnected') == p.trial.eyelink.setup.dummyconnected
				break;
            end
            if p.trial.eyelink.setup.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, p.trial.eyelink.setup.KB_PRESS );
            end
            
        otherwise          % Echo to tracker for remote control
            if p.trial.eyelink.setup.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, p.trial.eyelink.setup.KB_PRESS );
            end
	end % switch key


    % Get current target position from Eyelink
	[resp, tx, ty]= Eyelink( 'TargetCheck');
    if any(xy~=[tx;ty])
        fprintf('<<targ changed>>\nTarget XY: [%4.2f, %4.2f]\t', tx, ty);
        xy = [tx;ty];
    end
	
	
	% erased or moved: erase target
% % % 	if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
% % % 		pds.eyelink.cal.eraseTarget(p, tx,ty);
% % % 		targetvisible = 0;
% % % 	end
% % % 	% redraw if invisible
% % % 	if targetvisible==0 && result==1
% % % % 		fprintf( 'Target drawn at: x=%d, y=%d\n', tx, ty );
		if resp
            pds.eyelink.cal.drawTarget(p, xy);
        end
% % % 		targetvisible = 1;
% % % 		otx = tx;		% record position for future tests
% % % 		oty = ty;
% % % 		if p.trial.eyelink.setup.targetbeep==1 && p.trial.sound.use
% % % 			EyelinkCalTargetBeep(p);	% optional beep to alert subject
% % % 		end
% % % 	end
	
end % while IN_TARGET_MODE


% exit:					% CLEAN UP ON EXIT
% % % if p.trial.eyelink.setup.targetbeep==1 && p.trial.sound.use
% % % 	if Eyelink('CalResult')==1  % does 1 signal success?
% % % 		EyelinkCalDoneBeep(p, 1);
% % % 	else
% % % 	  	EyelinkCalDoneBeep(p, -1);
% % % 	end
% % % end
  
% % % if targetvisible==1
% % % 	pds.eyelink.cal.eraseTarget(p, tx,ty);   % erase target on exit, bit superfluous actually
% % % end

%% Clear screen & print result in command window
pause(.01); % brief pause or screen clear doesn't apply (?!?)
pds.eyelink.cal.clearDisplay(p);


[result, calmsg] = Eyelink('CalMessage');
% [result, calmsg] = Eyelink('readfromtracker', 'calibration_fixation_data');
if ~result
    % ...unknown format/content of CalMessage
    fprintf('\n');
else
    fprintf(2, '!!!\n')
end

return;
