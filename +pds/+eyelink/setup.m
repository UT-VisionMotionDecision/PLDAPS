function dv = setup(dv)
% dv = pds.eyelink.setup(dv)
% Setup PLDAPS to use Eyelink toolbox
if ~dv.defaultParameters.eyelink.use
    fprintf('****************************************************************\r')
    fprintf('****************************************************************\r')
    fprintf('PLDAPS is NOT using EYELINK Toolbox for eyetrace. \rUsing pds.datapixx.getEyePosition instead\r')
    return
else
    Eyelink('Initialize')
    
    if dv.defaultParameters.eyelink.custom_calibration;
        error('pldaps:eyelinkSetup','custom_calibration doesn''t work yet');
%         dv.defaultParameters.eyelink.custom_calibration = false; % this doesnt work yet
    end
    
    dv.defaultParameters.eyelink.setup=EyelinkInitDefaults(); % don't pass in the window pointer or you can mess up the color range
    
    dv.defaultParameters.eyelink.edfFile=datestr(dv.defaultParameters.session.initTime, 'mmddHHMM');
    
          
    dv.defaultParameters.eyelink.edfFileLocation = pwd; %dv.pref.datadir;
    fprintf('EDFFile: %s\n', dv.defaultParameters.eyelink.edfFile );
    
    dv.defaultParameters.eyelink.setup.window = dv.defaultParameters.display.ptr;
    % dv.defaultParameters.eyelink.backgroundcolour = BlackIndex(dv.defaultParameters.display.ptr);
    % dv.defaultParameters.eyelink.msgfontcolour    = WhiteIndex(dv.defaultParameters.display.ptr);
    % dv.defaultParameters.eyelink.imgtitlecolour   = WhiteIndex(dv.defaultParameters.display.ptr);
    % dv.defaultParameters.eyelink.targetbeep = 0;
    % dv.defaultParameters.eyelink.calibrationtargetcolour= WhiteIndex(dv.defaultParameters.eyelink.window);
    % dv.defaultParameters.eyelink.calibrationtargetsize= .5;
    % dv.defaultParameters.eyelink.calibrationtargetwidth=0.5;
    dv.defaultParameters.eyelink.setup.displayCalResults = 1;
    dv.defaultParameters.eyelink.setup.eyeimgsize=50;
    EyelinkUpdateDefaults(dv.defaultParameters.eyelink.setup);
    
    % check if eyelink initializes
    if ~Eyelink('IsConnected')
        fprintf('****************************************************************\r')
        fprintf('****************************************************************\r')
        fprintf('Eyelink Init aborted. Eyelink is not connected.\n');
        fprintf('PLDAPS is NOT using EYELINK Toolbox for eyetrace. \rUsing pds.datapixx.getEyePosition instead\r')
        fprintf('if you want to use EYELINK Toolbox for your eyetracking needs, \rtry Eyelink(''Shutdown'') and then retry dv = pds.eyelink.setup(dv)\r')
        
        Beeper(500); Beeper(400)
        disp('PRESS ENTER TO CONFIRM YOU READ THIS MESSAGE'); pause
        Eyelink('Shutdown')
        dv.defaultParameters.eyelink.use = 0;
        return
    end
    
    % open file to record data to
    % res = Eyelink('Openfile', fullfile(dv.defaultParameters.eyelink.edfFileLocation,dv.defaultParameters.eyelink.edfFile));
    res = Eyelink('Openfile', dv.defaultParameters.eyelink.edfFile);
    if res~=0
        fprintf('Cannot create EDF file ''%s'' ', dv.defaultParameters.eyelink.edfFile);
        Eyelink('Shutdown')
        return;
    end
    
    % Eyelink commands to setup the eyelink environment
    datestr(now);
    Eyelink('command',  ['add_file_preamble_text ''Recorded by PLDAPS'  '''']);
    Eyelink('command',  ['add_file_preamble_text ''Datafile: ' dv.defaultParameters.session.file  '''']);
    Eyelink('command',  'screen_pixel_coords = %ld, %ld, %ld, %ld', dv.defaultParameters.display.winRect(1), dv.defaultParameters.display.winRect(2), dv.defaultParameters.display.winRect(3)-1, dv.defaultParameters.display.winRect(4)-1);
    Eyelink('command',  'analog_dac_range = %1d, %1d', -5, 5);
    w = 10*dv.defaultParameters.display.widthcm/2;
    h = 10*dv.defaultParameters.display.heightcm/2;
    Eyelink('command',  'screen_phys_coords = %1d, %1d, %1d, %1d', -w, h, w, -h);
    Eyelink('command',  'screen_distance = %1d', dv.defaultParameters.display.viewdist*10);
    
    
    [v,vs] = Eyelink('GetTrackerVersion');
    disp('***************************************************************')
    fprintf('\tReading Values from %sEyetracker\r', vs)
    disp('***************************************************************')
    [result, reply] = Eyelink('ReadFromTracker', 'screen_pixel_coords');
    fprintf(['Screen pixel coordinates are:\t\t' reply '\r'])
    [result, reply] = Eyelink('ReadFromTracker', 'screen_phys_coords');
    fprintf(['Screen physical coordinates are:\t' reply ' (in mm)\r'])
    [result, reply] = Eyelink('ReadFromTracker', 'screen_distance');
    fprintf(['Screen distance is:\t\t\t' reply '\r'])
    [result, reply] = Eyelink('ReadFromTracker', 'analog_dac_range');
    fprintf(['Analog output range is constraiend to:\t' reply ' (volts)\r'])
    [result, srate] = Eyelink('ReadFromTracker', 'sample_rate');
    fprintf(['Sampling rate is:\t\t\t' srate 'Hz\r'])
    dv.defaultParameters.eyelink.srate = str2double(srate);
    pause(.05)
    
    vsn = regexp(vs,'\d','match'); % wont work on EL I
    if isempty(vsn)
        eyelinkI = 1;
    else
        eyelinkI = 0;
    end
    
    [result,reply]=Eyelink('ReadFromTracker','elcl_select_configuration');
    dv.defaultParameters.eyelink.trackerversion = vs;
    dv.defaultParameters.eyelink.trackermode    = reply;
    
    switch dv.defaultParameters.eyelink.trackermode
        case {'RTABLER'}
            fprintf('\rSetting up tracker for remote mode\r')
            % remote mode possible add HTARGET ( head target)
            
            Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
            % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
        otherwise
            dv.defaultParameters.eyelink.callback = [];
            Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT');
            % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,PUPIL,STATUS,INPUT');
    end
    
    
    % custom calibration points
    if dv.defaultParameters.eyelink.custom_calibration
        width  = dv.defaultParameters.display.winRect(3);
        height = dv.defaultParameters.display.winRect(4);
        disp('setting up custom calibration')
        disp('this is not properly implemented yet on 64-bit Eyelink. Works for 32-bit')
        Eyelink('command', 'generate_default_targets = NO');
        %     Eyelink('command','calibration_samples = 5');
        %     Eyelink('command','calibration_sequence = 1,2,3,4,5');
        scale = dv.defaultParameters.eyelink.custom_calibrationScale;

        cx = (width/2);
        cy = (height/2);
        Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
            cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
        
        fprintf('calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d\r',...
            cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
        %     Eyelink('command','validation_samples = 5');
        %     Eyelink('command','validation_sequence = 0,1,2,3,4,5');
        Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
            cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
        
        %TODO: what? that's not how it should be done, why not send the
        %calibration scale??
    else
        disp('using default calibration points')
        Eyelink('command', 'calibration_type = HV9');
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
    
    [result, dv.defaultParameters.eyelink.EYE_USED] = Eyelink('ReadFromTracker', 'active_eye');
    
    
    dv.defaultParameters.eyelink.eyeIdx = 1;
    if strcmp(dv.defaultParameters.eyelink.EYE_USED, 'RIGHT')
        dv.defaultParameters.eyelink.eyeIdx = 2;
    end
    
    Eyelink('message', 'SETUP');
    
    Eyelink('StartRecording');
end



