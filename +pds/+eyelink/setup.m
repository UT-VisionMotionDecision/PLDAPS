function p = setup(p)
%pds.eyelink.setup    setup eyelink at the beginning of an experiment
%
% p = pds.eyelink.setup(p)
% Setup PLDAPS to use Eyelink toolbox
%
% 20xx-xx-xx  AAA   Wrote it.
% 2018-03-28  TBC   Binocular compatibility
    
if p.trial.eyelink.use 
    
    if p.trial.eyelink.useAsEyepos
        p.trial.pldaps.modNames.tracker = 'eyelink';
    end
        
    fprintLineBreak;
    fprintf('\tSetting up EYELINK Toolbox for eyetrace. \n');
    fprintLineBreak;

        
    Eyelink('Initialize');
        
    p.trial.eyelink.setup=EyelinkInitDefaults(); % don't pass in the window pointer or you can mess up the color range
    
    p.trial.eyelink.edfFile=datestr(p.trial.session.initTime, 'mmddHHMM');
    
    p.trial.eyelink.edfFileLocation = pwd; %dv.pref.datadir;
    fprintf('EDFFile: %s\n', p.trial.eyelink.edfFile );
    
    p.trial.eyelink.setup.window = p.trial.display.ptr;
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
    err = Eyelink('Openfile', p.trial.eyelink.edfFile);
    if err
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
    
    
    %% Read & report eyelink values
    reportStr = cell(3,1); % reportStr{:,i) == {description, value, units}
    padlen = -40;    padchar = '.';

    [~, vs] = Eyelink('GetTrackerVersion');
    p.trial.eyelink.trackerversion = vs;
    fprintLineBreak;
    fprintf('\tReading Values from %sEyetracker\n', vs)
    fprintLineBreak;

    [~, reply]=Eyelink('ReadFromTracker','elcl_select_configuration');
    i = 1;    reportStr{1,i} = StrPad('Eyelink mode',padlen,padchar); reportStr{2,i} = reply;
    p.trial.eyelink.trackermode = reply;
    
    [~, reply] = Eyelink('ReadFromTracker', 'screen_pixel_coords');
    i = i+1;  reportStr{1,i} = StrPad('Screen pixel coords',padlen,padchar); reportStr{2,i} = reply; reportStr{3,i} = 'px';
    
    [~, reply] = Eyelink('ReadFromTracker', 'screen_phys_coords');
    i = i+1;  reportStr{1,i} = StrPad('Screen physical coords',padlen,padchar); reportStr{2,i} = reply; reportStr{3,i} = 'mm';
    
    reply = sprintf('%2.2f, %2.2f', screenTopDist, screenBtmDist); % no eyelink readout of screen_distance
    i = i+1;  reportStr{1,i} = StrPad('Subject viewing distance',padlen,padchar); reportStr{2,i} = reply; reportStr{3,i} = '[cm_to_top, cm_to_btm]';
    p.trial.eyelink.screenTopBtmDist = [screenTopDist, screenBtmDist];
    
    [~, reply] = Eyelink('ReadFromTracker', 'analog_dac_range');
    i = i+1;  reportStr{1,i} = StrPad('Analog output range',padlen,padchar); reportStr{2,i} = reply; reportStr{3,i} = 'V';
    
    [~, reply] = Eyelink('ReadFromTracker', 'sample_rate');
    i = i+1;  reportStr{1,i} = StrPad('Sampling rate',padlen,padchar); reportStr{2,i} = reply; reportStr{3,i} = 'Hz';
    p.trial.eyelink.srate = str2double(reply);
    
    % display output in command window
    fprintf('%s%s  %s\n', reportStr{:});
    
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
        
        % Example custom calibration parameter setup:
        %   .eyelink.custom_calibrationScale = 0.4;  % number
        %   .eyelink.calSettings.calibration_corner_scaling  = '0.85';    % string!
        %   .eyelink.calSettings.validation_corner_scaling   = '0.85';    % string!

        % %utomatically format/expand calibration scale param to the string input Eyelink expects
        if isfield(p.trial.eyelink, 'custom_calibrationScale')
            if isscalar(p.trial.eyelink.custom_calibrationScale)
                eyeCalScale = p.trial.eyelink.custom_calibrationScale*[1 1];
            else
                eyeCalScale = p.trial.eyelink.custom_calibrationScale(1:2);
            end
            p.trial.eyelink.calSettings.calibration_area_proportion = sprintf('%2.2f %2.2f', eyeCalScale);
        end
        
        % Allow user to manually set any eyelink values they want
        % Send all calibration settings present to eyetracker
        if isfield(p.trial.eyelink, 'calSettings')
            fn = fieldnames(p.trial.eyelink.calSettings);
            for i = 1:length(fn)
                Eyelink('command', sprintf('%s = %s', fn{i}, p.trial.eyelink.calSettings.(fn{i})));
            end
            
        else
            
            % Old crufty manual way. Not recommended.            
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
    
    % Done setting up. Get started!
    fprintLineBreak;
    Eyelink('message', 'SETUP');
    
    Eyelink('StartRecording');
end

end %pds.eyelink.setup


% % % % % % % % % 
%% Sub-Functions
% % % % % % % % %

function str = StrPad(in,len,char)
% str = StrPad(in,length,padchar)
% modified version of PTB StrPad to allow pre or post padding with sign of [len].
% (pre)pads IN with CHAR to sepcified length LEN. If inputs IN or PADCHAR
% are numerical, they will be converted to to string. If input is too long,
% it is truncated from the start to specified length.
%
% DN 2007
% 2018-08-15  TBC  Use sign of [len] for padding direction

if isnumeric(in) && length(in)==1 && in==round(in)
    % convert to string
    in = num2str(in);
end
if ~ischar(in)
    error('input must be char or scalar integer');
end

if isnumeric(char) && length(char)==1
    % convert to string
    char = num2str(char);
end

% padding before or after input string?
if len>0
    prepad = 1;
else
    prepad = 0;
end
len = abs(len);

if ischar(in)
    % check that we have a string
    inlen = length(in);
    if inlen >= len
        % truncate string if needed
        b = [];
        in = in(1:len);
    else
        % create pad string
        b = repmat(char, 1, len-inlen);
    end
end
% Create output
if prepad
    str = [b, in];
else
    str = [in, b];
end
    
end %StrPad

