function p = setup(p)
%pds.eyelink.setup    setup eyelink at the beginning of an experiment
%
% p = pds.eyelink.setup(p)
% Setup PLDAPS to use Eyelink toolbox
%
% 20xx-xx-xx  AAA   Wrote it.
% 2018-03-28  TBC   Binocular compatibility
    
if p.trial.eyelink.use 
    
    fprintLineBreak;
    fprintf('\tSetting up EYELINK Toolbox for eyetrace. \n');
    fprintLineBreak;

        
    Eyelink('Initialize');
    
% %     if p.trial.eyelink.custom_calibration
% %         error('pldaps:eyelinkSetup','custom_calibration doesn''t work yet');
% % %         dv.defaultParameters.eyelink.custom_calibration = false; % this doesnt work yet
% %     end
    
    p.trial.eyelink.setup=EyelinkInitDefaults(); % don't pass in the window pointer or you can mess up the color range
    
    p.trial.eyelink.edfFile=datestr(p.trial.session.initTime, 'mmddHHMM');
    
          
    p.trial.eyelink.edfFileLocation = pwd; %dv.pref.datadir;
    fprintf('EDFFile: %s\n', p.trial.eyelink.edfFile );
    
    p.trial.eyelink.setup.window = p.trial.display.ptr;
    % dv.defaultParameters.eyelink.backgroundcolour = BlackIndex(dv.defaultParameters.display.ptr);
    % dv.defaultParameters.eyelink.msgfontcolour    = WhiteIndex(dv.defaultParameters.display.ptr);
    % dv.defaultParameters.eyelink.imgtitlecolour   = WhiteIndex(dv.defaultParameters.display.ptr);
    % dv.defaultParameters.eyelink.targetbeep = 0;
    % dv.defaultParameters.eyelink.calibrationtargetcolour= WhiteIndex(dv.defaultParameters.eyelink.window);
    % dv.defaultParameters.eyelink.calibrationtargetsize= .5;
    % dv.defaultParameters.eyelink.calibrationtargetwidth=0.5;
    p.trial.eyelink.setup.displayCalResults = 1;
    p.trial.eyelink.setup.eyeimgsize=50;
    EyelinkUpdateDefaults(p.trial.eyelink.setup);
    
    % some default values (used in calibration; relieves dependency on other pldaps modules/subfields
    if ~isfield(p.trial.eyelink, 'fixdotW')
        p.trial.eyelink.fixdotW = ceil(0.2 * p.trial.display.ppd);
    end

    
    % check if eyelink initializes
    if ~Eyelink('IsConnected')
        fprintf('****************************************************************\r')
        fprintf('****************************************************************\r')
        fprintf('Eyelink Init aborted. Eyelink is not connected.\n');
        fprintf('PLDAPS is NOT using EYELINK Toolbox for eyetrace. \r')
        fprintf('if you want to use EYELINK Toolbox for your eyetracking needs, \rtry Eyelink(''Shutdown'') and then retry p = pds.eyelink.setup(p)\r')
        
        if p.trial.sound.use
            Beeper(500); Beeper(400)
        end
        disp('PRESS ENTER TO CONFIRM YOU READ THIS MESSAGE'); pause
        Eyelink('Shutdown')
        p.trial.eyelink.use = 0;
        return
    end
    
    % open file to record data to
    % res = Eyelink('Openfile', fullfile(dv.defaultParameters.eyelink.edfFileLocation,dv.defaultParameters.eyelink.edfFile));
    res = Eyelink('Openfile', p.trial.eyelink.edfFile);
    if res~=0
        fprintf('Cannot create EDF file ''%s'' ', p.trial.eyelink.edfFile);
        Eyelink('Shutdown')
        return;
    end
    
    %% Setup Eyelink enviro & report values in cmd window
    % Eyelink commands to setup the eyelink environment
    datestr(now);
    Eyelink('command',  ['add_file_preamble_text ''Recorded by PLDAPS'  '''']);
    Eyelink('command',  ['add_file_preamble_text ''Datafile: ' p.trial.session.file  '''']);
    Eyelink('command',  'screen_pixel_coords = %ld, %ld, %ld, %ld', p.trial.display.winRect(1), p.trial.display.winRect(2), p.trial.display.winRect(3)-1, p.trial.display.winRect(4)-1);
    Eyelink('command',  'analog_dac_range = %1d, %1d', -5, 5);
    w = round(10*p.trial.display.widthcm/2);
    h = round(10*p.trial.display.heightcm/2);
    Eyelink('command',  'screen_phys_coords = %1d, %1d, %1d, %1d', -w, h, w, -h);
    % Better estimates if screen_distance is provided in [<mm to top>, <mm to bottom>] than only [<mm to center>]  (per eyelink PHYSICAL.INI)
    %       Previously:   Eyelink('command',  'screen_distance = %1d', round(p.trial.display.viewdist*10)); % must be integer mm
    if ~isfield(p.trial.display, 'obsPos') % explicit observer position in cm xyz
        screenTopDist = hypot( p.trial.display.heightcm/2, p.trial.display.viewdist);
        screenBtmDist = screenTopDist;
    else
        screenTopDist = hypot( p.trial.display.heightcm/2 + p.trial.display.obsPos(2), p.trial.display.viewdist);
        screenBtmDist = hypot( p.trial.display.heightcm/2 - p.trial.display.obsPos(2), p.trial.display.viewdist);
    end
    Eyelink('command',  'screen_distance = %d, %d\n', 10*round(screenTopDist), 10*round(screenBtmDist) ); % cm to mm
    
    
    % Read & report eyelink values
    [~, vs] = Eyelink('GetTrackerVersion');
    p.trial.eyelink.trackerversion = vs;
    disp('***************************************************************')
    fprintf('\tReading Values from %sEyetracker\r', vs)
    disp('***************************************************************')

    reportStr = cell(3,1); % reportStr{:,i) == {description, value, units}
    [~, reply]=Eyelink('ReadFromTracker','elcl_select_configuration');
    i = 1;    reportStr{1,i} = 'Eyelink mode:'; reportStr{2,i} = reply;
    p.trial.eyelink.trackermode = reply;
    
    [~, reply] = Eyelink('ReadFromTracker', 'screen_pixel_coords');
    i = i+1;  reportStr{1,i} = 'Screen pixel coords:'; reportStr{2,i} = reply; reportStr{3,i} = 'px';
    
    [~, reply] = Eyelink('ReadFromTracker', 'screen_phys_coords');
    i = i+1;  reportStr{1,i} = 'Screen physical coords:'; reportStr{2,i} = reply; reportStr{3,i} = 'mm';
    
    reply = sprintf('%2.2f, %2.2f', screenTopDist, screenBtmDist); % no eyelink readout of screen_distance
    i = i+1;  reportStr{1,i} = 'Subject viewing distance:'; reportStr{2,i} = reply; reportStr{3,i} = '[cm_to_top, cm_to_btm]';
    p.trial.eyelink.screenTopBtmDist = [screenTopDist, screenBtmDist];
    
    [~, reply] = Eyelink('ReadFromTracker', 'analog_dac_range');
    i = i+1;  reportStr{1,i} = 'Analog output range:'; reportStr{2,i} = reply; reportStr{3,i} = 'V';
    
    [~, reply] = Eyelink('ReadFromTracker', 'sample_rate');
    i = i+1;  reportStr{1,i} = 'Sampling rate:'; reportStr{2,i} = reply; reportStr{3,i} = 'Hz';
    p.trial.eyelink.srate = str2double(reply);
    
    % show output in command window
    fprintf('%s\n\t\t\t\t\t\t%s  %s\n', reportStr{:});
    
%     fprintf(['Screen pixel coordinates:\t\t' elVal.px_coords '\r'])
%     fprintf('Screen physical coordinates:\t%2.2f, %2.2f, %2.2f, %2.2f  cm\r', str2num(reply)/10)
%     % [~, reply] = Eyelink('ReadFromTracker', 'screen_distance');  % % ..."Variable read not supported"
%     fprintf('Screen distance:\t%2.2f\t%2.2f  [cm_to_top, cm_to_btm]\r', screenTopDist, screenBtmDist)
%     [~, reply] = Eyelink('ReadFromTracker', 'analog_dac_range');
%     fprintf(['Analog output range:\t' reply '  V\r'])
%     [~, srate] = Eyelink('ReadFromTracker', 'sample_rate');
%     fprintf(['Sampling rate:\t\t\t' srate 'Hz\r'])
%     p.trial.eyelink.srate = str2double(srate);
%     pause(.05)
    
    %% Mode-specific setup
    switch p.trial.eyelink.trackermode
        case {'RTABLER'}
            fprintf('\rSetting up tracker for remote mode\r')
            % remote mode possible add HTARGET ( head target)
            
            Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
            % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT,HTARGET, HMARKER');
        otherwise
            p.trial.eyelink.callback = [];
            Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT');
            % set link data (used for gaze cursor)
            Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,PUPIL,STATUS,INPUT');
    end
    
    
    %% Eyelink calibration setup
    if p.trial.eyelink.custom_calibration
        
        if isfield(p.trial.eyelink, 'calSettings')
            % Allow user to manually set any eyelink values they want
            % Send all calibration settings present to eyetracker
            fn = fieldnames(p.trial.eyelink.calSettings);
            for i = 1:length(fn)
                Eyelink('command', sprintf('%s = %s', fn{i}, p.trial.eyelink.calSettings.(fn{i})));
            end
        else
            
            width  = p.trial.display.winRect(3);
            height = p.trial.display.winRect(4);
            disp('setting up custom calibration')
            disp('this is not properly implemented yet on 64-bit Eyelink. Works for 32-bit')
            Eyelink('command', 'generate_default_targets = NO');
            Eyelink('command','calibration_samples = 5');
            Eyelink('command','calibration_sequence = 1,2,3,4,5');
            scale = p.trial.eyelink.custom_calibrationScale;
            
            cx = (width/2);
            cy = (height/2);
            Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
                cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
            
            fprintf('calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d\r',...
                cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
            Eyelink('command','validation_samples = 5');
            Eyelink('command','validation_sequence = 0,1,2,3,4,5');
            Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
                cx,cy,  cx,cy-cy*scale,  cx,cy+cy*scale,  cx-cx*scale,cy,  cx + cx*scale,cy);
            
            %TODO: what? that's not how it should be done, why not send the
            %calibration scale??
        end
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
    [~, reply]=Eyelink('ReadFromTracker','enable_automatic_calibration');
    
    if reply % reply = 1
        fprintf('Automatic sequencing ON\r');
    else
        fprintf('Automatic sequencing OFF\r');
    end
    
    Eyelink('command',  'inputword_is_window = ON');
    
    
    pause(.05)
    
    % Map Eyelink eye-tracked settings to PLDAPS
    [~, p.trial.eyelink.EYE_USED] = Eyelink('ReadFromTracker', 'active_eye');
    
    [~, isBino] = Eyelink('ReadFromTracker', 'binocular_enabled');
    if isBino
        p.trial.eyelink.EYE_USED = 'BINO';
    end
    
    p.trial.eyelink.eyeIdx = 1;
    if strcmpi(p.trial.eyelink.EYE_USED, 'RIGHT')
        p.trial.eyelink.eyeIdx = 2;
    elseif strcmpi(p.trial.eyelink.EYE_USED, 'BINO')
        p.trial.eyelink.eyeIdx = [1, 2];
        % Nope. Assigning different colors for each eye causes error
        % when only one 'eyepos' value returned (e.g. .mouse.useAsEyepos==1)
        %   p.defaultParameters.display.clut.eyepos = [p.defaultParameters.display.clut.eye1, p.defaultParameters.display.clut.eye2];
    end
    
    Eyelink('message', 'SETUP');
    
    Eyelink('StartRecording');
end



