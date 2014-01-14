function dv = pdsEyelinkSetup(dv)
% dv = pdsEyelinkSetup(dv)
% Setup PLDAPS to use Eyelink toolbox

dv.el.customCalibration = 0; % this doesnt work yet

dv.el=EyelinkInitDefaults(dv.disp.ptr);

% filename can only be 8 characters long (not including extention
dtstr = datestr(now, 'dHHMM');
if numel(dtstr)>5
    dtstr = dtstr(end-4:end);
end
% dv.el.edfFile = [dv.subj(1:3) dtstr]; %[dv.pref.sfile(1:end-4) '.edf'];
% dv.el.edfFileLocation = dv.pref.datadir;

dv.el.edfFile = 'pds.edf'; %[dv.subj(1:3) dtstr]; %[dv.pref.sfile(1:end-4) '.edf'];
dv.el.edfFileLocation = pwd; %dv.pref.datadir;
fprintf('EDFFile: %s\n', dv.el.edfFile );

dv.el.window = dv.disp.ptr; 
% dv.el.backgroundcolour = BlackIndex(dv.disp.ptr);
% dv.el.msgfontcolour    = WhiteIndex(dv.disp.ptr);
% dv.el.imgtitlecolour   = WhiteIndex(dv.disp.ptr);
% dv.el.targetbeep = 0;
% dv.el.calibrationtargetcolour= WhiteIndex(dv.el.window);
% dv.el.calibrationtargetsize= .5;
% dv.el.calibrationtargetwidth=0.5;
dv.el.displayCalResults = 1;
dv.el.eyeimgsize=50;
EyelinkUpdateDefaults(dv.el);

% check if eyelink initializes
if ~EyelinkInit
    fprintf('Eyelink Init aborted.\n');
    Eyelink('Shutdown')
    sca
    return
end

% open file to record data to
% res = Eyelink('Openfile', fullfile(dv.el.edfFileLocation,dv.el.edfFile));
res = Eyelink('Openfile', dv.el.edfFile);
if res~=0
    fprintf('Cannot create EDF file ''%s'' ', dv.el.edfFile);
    Eyelink('Shutdown')
    return;
end

% Eyelink commands to setup the eyelink environment
datestr(now);
Eyelink('command',  ['add_file_preamble_text ''Recorded by PLDAPS'  '''']);
Eyelink('command',  'screen_pixel_coords = %ld, %ld, %ld, %ld', dv.disp.winRect(1), dv.disp.winRect(2), dv.disp.winRect(3)-1, dv.disp.winRect(4)-1);
Eyelink('command',  'analog_dac_range = %1d, %1d', -5, 5);
Eyelink('command',  'screen_phys_coords = %1d, %1d, %1d, %1d', -dv.disp.widthcm/2, dv.disp.heightcm/2, dv.disp.widthcm/2, -dv.disp.heightcm/2);


[v,vs] = Eyelink('GettrackerVersion');
disp('***************************************************************')
fprintf('\tReading Values from %sEyetracker\r', vs)
disp('***************************************************************')
[result, reply] = Eyelink('ReadFromTracker', 'screen_pixel_coords'); %#ok<*ASGLU>
fprintf(['Screen pixel coordinates are:\t\t' reply '\r'])
[result, reply] = Eyelink('ReadFromTracker', 'screen_phys_coords');
fprintf(['Screen physical coordinates are:\t' reply ' (in mm)\r'])
[result, reply] = Eyelink('ReadFromTracker', 'screen_distance');
fprintf(['Screen distance is:\t\t\t' reply '\r'])
[result, reply] = Eyelink('ReadFromTracker', 'analog_dac_range');
fprintf(['Analog output range is constraiend to:\t' reply ' (volts)\r'])
[result, srate] = Eyelink('ReadFromTracker', 'sample_rate');
fprintf(['Sampling rate is:\t\t\t' srate 'Hz\r'])
dv.el.srate = srate; 
pause(.05)


[result,reply]=Eyelink('ReadFromTracker','elcl_select_configuration');
dv.el.trackerVersion = vs; 
dv.el.trackerMode    = reply;

switch dv.el.trackerMode
    case {'RTABLER'}
        fprintf('\rSetting up tracker for remote mode\r')
        % remote mode possible add HTARGET ( head target)
        
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
        % set link data (used for gaze cursor)
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
    otherwise
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT');
        % set link data (used for gaze cursor)
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,PUPIL,STATUS,INPUT');
end


% custom calibration points
if dv.el.customCalibration
    width  = dv.disp.winRect(3); 
    height = dv.disp.winRect(4); 
    disp('setting up custom calibration')
    disp('this is not properly implemented yet')
    Eyelink('command', 'generate_default_targets = NO');
    Eyelink('command','calibration_samples = 5');
    Eyelink('command','calibration_sequence = 1,2,3,4,5');
    Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
        width/2,height/2,  width/2,height*0.2,  width/2,height - height*0.2,  width*0.2,height/2,  width - width*0.2,height/2 );
    
    fprintf('calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d\r',...
        width/2,height/2,  width/2,height*0.2,  width/2,height - height*0.2,  width*0.2,height/2,  width - width*0.2,height/2);
    
    
    Eyelink('command','validation_samples = 5');
    Eyelink('command','validation_sequence = 0,1,2,3,4,5');
    Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
        width/2,height/2,  width/2,height*0.2,  width/2,height - height*0.2,  width*0.2,height/2,  width - width*0.2,height/2 );
else
    disp('using default calibration points')
    Eyelink('command', 'calibration_type = HV5');
    % you must send this command with value NO for custom calibration
    % you must also reset it to YES for subsequent experiments
    Eyelink('command', 'generate_default_targets = YES');
    
end



% query host to see if automatic calibration sequencing is enabled.
% ReadFromTracker needs to have 2 outputs.
% variables querable are listed in the .ini files in the host
% directories. Note that not all variables are querable.
[result, reply]=Eyelink('ReadFromTracker','enable_automatic_calibration');

if reply % reply = 1
    fprintf('Automatic sequencing ON\r');
else
    fprintf('Automatic sequencing OFF\r');
end

Eyelink('command',  'inputword_is_window = ON');
       
       
pause(.05)

% dv.el.initBool = false;
dv.el.maxTrialLength = 9; % in seconds
dv.el.bufferSampleLength = 31;  % I'm not sure where to put this variable - I think it may be rig specific
dv.el.bufferEventLength = 30;

dv.useEyelink = 1;
       
Eyelink('message', 'SETUP');

Eyelink('StartRecording');


       
