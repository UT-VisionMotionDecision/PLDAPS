function result=EyelinkTargetModeDisplay(dv)

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

tx=dv.el.MISSING;
ty=dv.el.MISSING;

otx=dv.el.MISSING;    % current target position
oty=dv.el.MISSING;

EyelinkClearCalDisplay(dv);	% setup_cal_display()

key=1;
while key~= 0
	[key, dv.el]=EyelinkGetKey(dv.el);		% dump old keys
end
				% LOOP WHILE WE ARE DISPLAYING TARGETS
stop=0;
while stop==0 && bitand(Eyelink('CurrentMode'), dv.el.IN_TARGET_MODE)

	if Eyelink( 'IsConnected' )==dv.el.notconnected
		result=-1;
		return;
	end;

	[key, dv.el]=EyelinkGetKey(dv.el);		% getkey() HANDLE LOCAL KEY PRESS

	switch key 
		case dv.el.TERMINATE_KEY,       % breakout key code
			EyelinkClearCalDisplay(dv); % clear_cal_display();
			result=dv.el.TERMINATE_KEY;
			return;
		case dv.el.SPACE_BAR,	         		% 32: accept fixation
			if dv.el.allowlocaltrigger==1
				Eyelink( 'AcceptTrigger');
			end
			break;
		case { 0,  dv.el.JUNK_KEY	}	% No key
		case dv.el.ESC_KEY,
			if Eyelink('IsConnected') == dv.el.dummyconnected
				stop=1;
			end
		    if dv.el.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, dv.el.KB_PRESS );
			end
		otherwise,          % Echo to tracker for remote control
		    if dv.el.allowlocalcontrol==1 
	       		Eyelink('SendKeyButton', key, 0, dv.el.KB_PRESS );
			end
	end % switch key


				% HANDLE TARGET CHANGES
	[result, tx, ty]= Eyelink( 'TargetCheck');
	
	
	% erased or moved: erase target
	if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
		EyelinkEraseCalTarget(dv, tx,ty);
		targetvisible = 0;
	end
	% redraw if invisible
	if targetvisible==0 && result==1
% 		fprintf( 'Target drawn at: x=%d, y=%d\n', tx, ty );
		
		EyelinkDrawCalTarget(dv, tx, ty);
		targetvisible = 1;
		otx = tx;		% record position for future tests
		oty = ty;
		if dv.el.targetbeep==1
			EyelinkCalTargetBeep(dv.el);	% optional beep to alert subject
		end
	end
	
end % while IN_TARGET_MODE


% exit:					% CLEAN UP ON EXIT
if dv.el.targetbeep==1
	if Eyelink('CalResult')==1  % does 1 signal success?
		EyelinkCalDoneBeep(dv.el, 1);
	else
	  	EyelinkCalDoneBeep(dv.el, -1);
	end
end
  
if targetvisible==1
	EyelinkEraseCalTarget(dv, tx,ty);   % erase target on exit, bit superfluous actually
end
EyelinkClearCalDisplay(dv); % clear_cal_display();

result=0;
return;
