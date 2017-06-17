function s=demoParameters(s)
 if nargin<1
	s=struct;
 end

 
 PLDAPSPath=mfilename('fullpath');
 seps=strfind(PLDAPSPath,filesep); 
 PLDAPSPath=PLDAPSPath(1:seps(end-1)-1);
 
%s.	.
%s.	behavior.
%s.	behavior.	reward.
 s.	behavior.	reward.	defaultAmount = 0;

%s.	datapixx.
 s.	datapixx.	use = false;
 
%s.	display.
 s.	display.	heightcm = 45;
 s.	display.	normalizeColor = 1;
 s.	display.	screenSize = [ ];
 s.	display.	scrnNum = 0;
 s.	display.	useOverlay = 2;
 s.	display.	viewdist = 57;
 s.	display.	widthcm = 63;

%s.	eyelink.
 s.	eyelink.	use = false;
 
%s.	mouse.
 s.	mouse.	initialCoordinates = [];
 s.	mouse.	use = true;
 s.	mouse.	useAsEyepos = true;
 s.	mouse.	useLocalCoordinates = true;
 
%s.	pldaps.
 s.	pldaps.	nosave = true;

%s.	pldaps.	dirs.
 s.	pldaps.	dirs.	data = [PLDAPSPath filesep 'data'];
 s.	pldaps.	dirs.	wavfiles = [PLDAPSPath filesep 'beepsounds'];

%s.	pldaps.	draw.	grid.
 s.	pldaps.	draw.	grid.	use = true;

%s.	pldaps.	pause.
 s.	pldaps.	pause.	preExperiment = false;

%s.	pldaps.	save.
 s.	pldaps.	save.	trialTempfiles = 0;

%s.	sound.
 s.	sound.	use = true;
 s.	sound.	useForReward = true;
end