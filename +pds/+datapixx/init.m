function p =  init(p)
%pds.datapixx.init    initialize Datapixx at the beginning of an experiment.
% p =  pds.datapixx.init(p)
%
% pds.datapixx.init is a function that intializes the DATAPIXX, preparing it for
% experiments. Critically, the PSYCHIMAGING calls sets up the dual CLUTS
% (Color Look Up Table) for two screens.  These two CLUTS are in the
% p.trial.display substruct
% INPUTS
%       p.trial [struct] - main pldaps display variables structure
%           .dispplay [struct] - required display
%               .ptr         - pointer to open PTB window
%               .useOverlay  - (0,1,2) for whether to use CLUT overlay
%                       0 - no overlay
%                       1 - Datapixx overlay (if datapixx.use is off, draws
%                                             overlay version)
%                       2 - Software overlay (requires stereomode setup)
%               .gamma.table - required ( can be a linear gamma table )
%               .humanCLUT   [256 x 3] human color look up table
%               .monkeyCLUT  [256 x 3] monkey color look up table
% OUTPUTS
%       p [modified]
%           .trial.display.overlayptr - pointer to overlay window added
%
%           if useOverlay == 1, pds.datapixx.init opens an overlay pointer
%           with p.trial.display.monkeyCLUT as the color look up table for one
%           datapixx monitor and p.trial.display.humanCLUT for the other monitor.
%
% Datapixx is Opened and set to default settings for PLDAPS


% 2011       kme wrote it
% 12/03/2013 jly reboot for version 3
% 2014       adapt to version 4.1
% 2016       jly add software overlay
global dpx GL;

if p.trial.datapixx.use
    
    if ~Datapixx('IsReady')
        Datapixx('Open');
    end
    
    % From help PsychDataPixx:
    % Timestamping is disabled by default (mode == 0), as it incurs a bit of
    % computational overhead to acquire and log timestamps, typically up to 2-3
    % msecs of extra time per 'Flip' command.
    % Buffer is collected at the end of the expeiment!
    PsychDataPixx('LogOnsetTimestamps',p.trial.datapixx.LogOnsetTimestampLevel);%2
    PsychDataPixx('ClearTimestampLog');
    
    %set getPreciseTime options, see testsuite/pldapsTimingTests for
    %details
    if ~isempty(p.trial.datapixx.GetPreciseTime.syncmode)
        dpx.syncmode=p.trial.datapixx.GetPreciseTime.syncmode; %1,2,3
    end
    if ~isempty(p.trial.datapixx.GetPreciseTime.maxDuration)
        dpx.maxDuration=p.trial.datapixx.GetPreciseTime.maxDuration;
    end
    if ~isempty(p.trial.datapixx.GetPreciseTime.optMinwinThreshold)
        dpx.optMinwinThreshold=p.trial.datapixx.GetPreciseTime.optMinwinThreshold;
    end
    
    if Datapixx('IsPropixx')
        %this might not work reliably
        if ~Datapixx('IsPropixxAwake')
            Datapixx('SetPropixxAwake');
        end
        Datapixx('EnablePropixxLampLed');
        
        if p.trial.datapixx.enablePropixxRearProjection
            Datapixx('EnablePropixxRearProjection');
        else
            Datapixx('DisablePropixxRearProjection');
        end
        
        if p.trial.datapixx.enablePropixxCeilingMount
            Datapixx('EnablePropixxCeilingMount');
        else
            Datapixx('DisablePropixxCeilingMount');
        end
    end
    
    p.trial.datapixx.info.DatapixxFirmwareRevision = Datapixx('GetFirmwareRev');
    p.trial.datapixx.info.DatapixxRamSize = Datapixx('GetRamSize');
       
    %%% Open Datapixx and get ready for data aquisition %%%
    Datapixx('StopAllSchedules');
    Datapixx('DisableDinDebounce');
    Datapixx('EnableAdcFreeRunning');
    Datapixx('SetDinLog');
    Datapixx('StartDinLog');
    Datapixx('SetDoutValues',0);
    Datapixx('RegWrRd');
    
    %start adc data collection if requested
    pds.datapixx.adc.start(p);
end

if p.trial.display.useOverlay==1 % Datapixx overlay
    if p.trial.datapixx.use
        disp('****************************************************************')
        disp('****************************************************************')
        disp('Adding Overlay Pointer')
        disp('Combining color look up tables that can be found in')
        disp('dv.disp.humanCLUT and dv.disp.monkeyCLUT')
        disp('****************************************************************')
        
        %check if transparant color is availiable? but how? firmware versions
        %differ between all machines...hmm, instead:
        %Set the transparancy color to the background color. Could set it
        %to anything, but we'll use this to maximize backward compatibility
        bgColor=p.trial.display.bgColor;
        if isField(p.trial, 'display.gamma.table')
            bgColor = interp1(linspace(0,1,256),p.trial.display.gamma.table(:,1), p.trial.display.bgColor);
        elseif isField(p.trial, 'display.gamma.power')
            % outcolor = incolor ^ EncodingGamma.
            bgColor =  p.trial.display.bgColor .^ p.trial.display.gamma.power;
        end
        Datapixx('SetVideoClutTransparencyColor', bgColor);
        Datapixx('EnableVideoClutTransparencyColorMode');
        Datapixx('RegWr');
        
        if p.trial.display.switchOverlayCLUTs
            combinedClut = [p.trial.display.humanCLUT; p.trial.display.monkeyCLUT];
        else
            combinedClut = [p.trial.display.monkeyCLUT; p.trial.display.humanCLUT];
        end
        %%% Gamma correction for dual CLUT %%%
        % check if gamma correction has been run on the window pointer
        if isField(p.trial, 'display.gamma.table')
            % get size of the combiend CLUT. It should be 512 x 3 (two 256 x 3 CLUTS
            % on top of eachother).
            sc = size(combinedClut);
            
            % use sc to make a vector of 8-bit color steps from 0-1
            x = linspace(0,1,sc(1)/2);
            % use the gamma table to lookup what the values should be
            y = interp1(x,p.trial.display.gamma.table(:,1), combinedClut(:));
            % reshape the combined clut back to 512 x 3
            combinedClut = reshape(y, sc);
        elseif isField(p.trial, 'display.gamma.power')            
            combinedClut=combinedClut .^ p.trial.display.gamma.power;
            
        end

        % WARNING about LoadNormalizedGammaTable from Mario Kleiner:
        % "Not needed, possibly harmful:
        % The PsychImaging() setup code already calls LoadIdentityClut()
        % which loads a proper gamma table. Depending on operating system
        % and gpu the tables need to differ a bit to compensate for driver
        % bugs. The LoadIdentityClut routine knows a couple of different
        % tables for different buggy systems. The automatic test code in
        % BitsPlusIdentityClutTest and BitsPlusImagingPipelinetest also
        % loads an identity lut via LoadIdentityClut and tests if that lut
        % is working correctly for your gpu ? and tries to auto-fix that lut
        % via an automatic optimization procedure if it isn?t correct. With
        % your ?LoadNormalized?? command you are overwriting that optimal
        % and tested lut, so you could add distortions to the video signal
        % that is sent to the datapixx. A wrong lut could even erroneously
        % trigger display dithering and add random imperceptible noise to
        % the displayed image ? at least that is what i observed on my
        % MacBookPro with ati graphics under os/x 10.4.11.?
        % (posted on Psychtoolbox forum, 3/9/2010)
        %
        % We don't seem to have this problem - jake 12/04/13
        Screen('LoadNormalizedGammaTable', p.trial.display.ptr, combinedClut, 2);
    end
elseif p.trial.display.useOverlay==2 % software overlay

    %assign transparency color
    bgColor=p.trial.display.bgColor;
    glUniform3f(glGetUniformLocation(p.trial.display.shader, 'transparencycolor'), bgColor(1), bgColor(2), bgColor(3));
    
    if p.trial.display.switchOverlayCLUTs
        combinedClut = [p.trial.display.humanCLUT; p.trial.display.monkeyCLUT];
    else
        combinedClut = [p.trial.display.monkeyCLUT; p.trial.display.humanCLUT];
    end

    % assign values to look up textures
    % Bind relevant texture object:
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, p.trial.display.lookupstexs(1));
    % Set filters properly: Want nearest neighbour filtering, ie., no filtering
    % at all. We'll do our own linear filtering in the ICM shader. This way
    % we can provide accelerated linear interpolation on all GPU's with all
    % texture formats, even if GPU's are old:
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MAG_FILTER, GL.NEAREST)
    % Want clamp-to-edge behaviour to saturate at minimum and maximum
    % intensity value, and to make sure that a pure-luminance 1 row clut is
    % properly "replicated" to all three color channels in rgb modes:
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    % Assign lookuptable data to texture:
    n=size(p.trial.display.humanCLUT, 1);
    m=size(p.trial.display.humanCLUT, 2);
    glTexImage2D(GL.TEXTURE_RECTANGLE_EXT, 0, p.trial.display.internalFormat,n,m, 0,GL.LUMINANCE, GL.FLOAT, single(combinedClut(1:n,:)));
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, 0);

    %#2
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, p.trial.display.lookupstexs(2));
    % Set filters properly: Want nearest neighbour filtering, ie., no filtering
    % at all. We'll do our own linear filtering in the ICM shader. This way
    % we can provide accelerated linear interpolation on all GPU's with all
    % texture formats, even if GPU's are old:
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MAG_FILTER, GL.NEAREST)
    % Want clamp-to-edge behaviour to saturate at minimum and maximum
    % intensity value, and to make sure that a pure-luminance 1 row clut is
    % properly "replicated" to all three color channels in rgb modes:
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    % Assign lookuptable data to texture:
    glTexImage2D(GL.TEXTURE_RECTANGLE_EXT, 0, p.trial.display.internalFormat, n, m, 0, GL.LUMINANCE, GL.FLOAT, single(combinedClut(n+1:end,:)));
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, 0);
end

Screen('Flip', p.trial.display.ptr, 0);
