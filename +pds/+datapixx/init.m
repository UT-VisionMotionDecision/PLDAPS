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
%               .useOverlay  - boolean for whether to use CLUT overlay
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
global dpx;

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
        dpx.syncmode=2; %1,2,3
    end
    if ~isempty(p.trial.datapixx.GetPreciseTime.maxDuration)
        dpx.maxDuration=0.02;
    end
    if ~isempty(p.trial.datapixx.GetPreciseTime.optMinwinThreshold)
        dpx.optMinwinThreshold=6.5e-5;
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
    
    if p.trial.display.useOverlay
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
        if isfield(p.trial, 'display.gamma.table')
            bgColor = interp1(linspace(0,1,256),p.trial.display.gamma.table(:,1), p.trial.display.bgColor);
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
        if isfield(p.trial, 'display.gamma.table')
            % get size of the combiend CLUT. It should be 512 x 3 (two 256 x 3 CLUTS
            % on top of eachother). 
            sc = size(combinedClut);

            % use sc to make a vector of 8-bit color steps from 0-1
            x = linspace(0,1,sc(1)/2);
            % use the gamma table to lookup what the values should be
            y = interp1(x,p.trial.display.gamma.table(:,1), combinedClut(:));
            % reshape the combined clut back to 512 x 3
            combinedClut = reshape(y, sc);
        end
    
        p.trial.display.overlayptr = PsychImaging('GetOverlayWindow', p.trial.display.ptr); % , dv.params.bgColor);
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
    else
        p.trial.display.overlayptr = p.trial.display.ptr;
    end
    
    
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
else
    if p.trial.display.useOverlay
        % this is abandoned test code to show how to create a dual clut
        % system without datapixx, by assigning different clut to two
        % screens in mirror modes.  However OsX cannot mix mirror and
        % extendet mode (well it can, but uses software mirroring in that
        % case). As we typically want a controller screen for the matlab
        % session window, I did not pursue this
        %TODO: 
        % 1: throw error unless some debug variable is set
        % 2: have switch to either to this or make overlaypointer a pointer
        % to an invisible window or a second one.
%         a1=Screen('ReadNormalizedGammaTable',1,1);
%         a2=Screen('ReadNormalizedGammaTable',2,1);
%         
%         
%         Screen('LoadNormalizedGammaTable', 1, a2,0);
%         Screen('LoadNormalizedGammaTable', 2, a2,0);
%        
%         
%         a1=Screen('ReadNormalizedGammaTable',1,1);
%         a2=Screen('ReadNormalizedGammaTable',2,1);
%         a2(:,3)=0;
%         
%         Screen('LoadNormalizedGammaTable', 1, a1, 0,1);
%         Screen('LoadNormalizedGammaTable', 2, a2, 0, 1);        
%         
%         b1=Screen('ReadNormalizedGammaTable',1,1);
%         b2=Screen('ReadNormalizedGammaTable',2,1);

%             dv.defaultParameters.display.overlay.experimentorOnlyOffset = dv.defaultParameters.display.bgColor(1); %TODO allow non gray bgColor
%             dv.defaultParameters.display.overlay.experimentorOnlyFactor = 0.0*256;
%             
%             dv.defaultParameters.display.overlay.bothOffset = 0.0;
%             dv.defaultParameters.display.overlay.bothFactor = 1*256;

        warning('pldaps:datapixxInit','Overlay requested, but not Datapixx disabled. Assuming debug scenario. Will assign ptr to overlayptr');
    end
    p.trial.display.overlayptr = p.trial.display.ptr;

end