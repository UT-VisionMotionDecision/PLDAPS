function result=targetModeDisplay(p)
%pds.eyelink.targetModeDisplay   set eyelink into target mode
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


result=-1; % initialize
if nargin < 1
	error( 'USAGE: result=EyelinkTargetModeDisplay(el)' );
end

targetvisible = 0;	% target currently drawn
targetrect=[0 0 0 0];

tx=p.trial.eyelink.setup.MISSING;
ty=p.trial.eyelink.setup.MISSING;

otx=p.trial.eyelink.setup.MISSING;    % current target position
oty=p.trial.eyelink.setup.MISSING;

pds.eyelink.clearCalDisplay(p);	% setup_cal_display()

key=1;
while key~= 0
	[key, p.trial.eyelink.setup]=EyelinkGetKey(p.trial.eyelink.setup);		% dump old keys
end
				% LOOP WHILE WE ARE DISPLAYING TARGETS
stop=0;
while stop==0 && bitand(Eyelink('CurrentMode'), p.trial.eyelink.setup.IN_TARGET_MODE)

	if Eyelink( 'IsConnected' )==p.trial.eyelink.setup.notconnected
		result=-1;
		return;
	end;

	[key, p.trial.eyelink.setup]=EyelinkGetKey(p.trial.eyelink.setup);		% getkey() HANDLE LOCAL KEY PRESS

	switch key 
		case p.trial.eyelink.setup.TERMINATE_KEY,       % breakout key code
			pds.eyelink.clearCalDisplay(p); % clear_cal_display();
			result=p.trial.eyelink.setup.TERMINATE_KEY;
			return;
		case p.trial.eyelink.setup.SPACE_BAR,	         		% 32: accept fixation
            if p.trial.eyelink.setup.allowlocaltrigger==1
				Eyelink( 'AcceptTrigger');
            end
            pds.behavior.reward.give(p);
            
			break;
		case { 0,  p.trial.eyelink.setup.JUNK_KEY	}	% No key
		case p.trial.eyelink.setup.ESC_KEY,
            if Eyelink('IsConnected') == p.trial.eyelink.setup.dummyconnected
				stop=1;
            end
            if p.trial.eyelink.setup.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, p.trial.eyelink.setup.KB_PRESS );
            end
		otherwise,          % Echo to tracker for remote control
            if p.trial.eyelink.setup.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, p.trial.eyelink.setup.KB_PRESS );
            end
	end % switch key


				% HANDLE TARGET CHANGES
	[result, tx, ty]= Eyelink( 'TargetCheck');
	
	
	% erased or moved: erase target
	if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
		pdsEyelinkEraseCalTarget(p, tx,ty);
		targetvisible = 0;
	end
	% redraw if invisible
	if targetvisible==0 && result==1
% 		fprintf( 'Target drawn at: x=%d, y=%d\n', tx, ty );
		
		pdsEyelinkDrawCalTarget(p, tx, ty);
		targetvisible = 1;
		otx = tx;		% record position for future tests
		oty = ty;
		if p.trial.eyelink.setup.targetbeep==1 && p.trial.sound.use
			EyelinkCalTargetBeep(p);	% optional beep to alert subject
		end
	end
	
end % while IN_TARGET_MODE


% exit:					% CLEAN UP ON EXIT
if p.trial.eyelink.setup.targetbeep==1 && p.trial.sound.use
	if Eyelink('CalResult')==1  % does 1 signal success?
		EyelinkCalDoneBeep(p, 1);
	else
	  	EyelinkCalDoneBeep(p, -1);
	end
end
  
if targetvisible==1
	pdsEyelinkEraseCalTarget(p, tx,ty);   % erase target on exit, bit superfluous actually
end
pds.eyelink.clearCalDisplay(p); % clear_cal_display();

result=0;
return;
