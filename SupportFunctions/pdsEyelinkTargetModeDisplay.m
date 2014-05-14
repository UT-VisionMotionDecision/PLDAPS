function result=pdsEyelinkTargetModeDisplay(dv)

% USAGE: result=EyelinkTargetModeDisplay(el)
%
%		el: Eyelink default values
% History
% 15-05-01	fwc created first version
% 22-05-01	fwc	little debugging
% 02-06-01	fwc removed use of global el, as suggested by John Palmer.
%   22-06-06    fwc OSX-ed


result=-1; % initialize
if nargin < 1
	error( 'USAGE: result=EyelinkTargetModeDisplay(el)' );
end

targetvisible = 0;	% target currently drawn
targetrect=[0 0 0 0];

tx=dv.trial.eyelink.setup.MISSING;
ty=dv.trial.eyelink.setup.MISSING;

otx=dv.trial.eyelink.setup.MISSING;    % current target position
oty=dv.trial.eyelink.setup.MISSING;

pdsEyelinkClearCalDisplay(dv);	% setup_cal_display()

key=1;
while key~= 0
	[key, dv.trial.eyelink.setup]=EyelinkGetKey(dv.trial.eyelink.setup);		% dump old keys
end
				% LOOP WHILE WE ARE DISPLAYING TARGETS
stop=0;
while stop==0 && bitand(Eyelink('CurrentMode'), dv.trial.eyelink.setup.IN_TARGET_MODE)

	if Eyelink( 'IsConnected' )==dv.trial.eyelink.setup.notconnected
		result=-1;
		return;
	end;

	[key, dv.trial.eyelink.setup]=EyelinkGetKey(dv.trial.eyelink.setup);		% getkey() HANDLE LOCAL KEY PRESS

	switch key 
		case dv.trial.eyelink.setup.TERMINATE_KEY,       % breakout key code
			pdsEyelinkClearCalDisplay(dv); % clear_cal_display();
			result=dv.trial.eyelink.setup.TERMINATE_KEY;
			return;
		case dv.trial.eyelink.setup.SPACE_BAR,	         		% 32: accept fixation
            if dv.trial.eyelink.setup.allowlocaltrigger==1
				Eyelink( 'AcceptTrigger');
            end
            pdsDatapixxAnalogOut(.1)
            
			break;
		case { 0,  dv.trial.eyelink.setup.JUNK_KEY	}	% No key
		case dv.trial.eyelink.setup.ESC_KEY,
            if Eyelink('IsConnected') == dv.trial.eyelink.setup.dummyconnected
				stop=1;
            end
            if dv.trial.eyelink.setup.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, dv.trial.eyelink.setup.KB_PRESS );
            end
		otherwise,          % Echo to tracker for remote control
            if dv.trial.eyelink.setup.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, dv.trial.eyelink.setup.KB_PRESS );
            end
	end % switch key


				% HANDLE TARGET CHANGES
	[result, tx, ty]= Eyelink( 'TargetCheck');
	
	
	% erased or moved: erase target
	if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
		pdsEyelinkEraseCalTarget(dv, tx,ty);
		targetvisible = 0;
	end
	% redraw if invisible
	if targetvisible==0 && result==1
% 		fprintf( 'Target drawn at: x=%d, y=%d\n', tx, ty );
		
		pdsEyelinkDrawCalTarget(dv, tx, ty);
		targetvisible = 1;
		otx = tx;		% record position for future tests
		oty = ty;
		if dv.trial.eyelink.setup.targetbeep==1
			EyelinkCalTargetBeep(dv);	% optional beep to alert subject
		end
	end
	
end % while IN_TARGET_MODE


% exit:					% CLEAN UP ON EXIT
if dv.trial.eyelink.setup.targetbeep==1
	if Eyelink('CalResult')==1  % does 1 signal success?
		EyelinkCalDoneBeep(dv, 1);
	else
	  	EyelinkCalDoneBeep(dv, -1);
	end
end
  
if targetvisible==1
	pdsEyelinkEraseCalTarget(dv, tx,ty);   % erase target on exit, bit superfluous actually
end
pdsEyelinkClearCalDisplay(dv); % clear_cal_display();

result=0;
return;
