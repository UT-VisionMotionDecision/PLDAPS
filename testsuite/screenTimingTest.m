function p=screenTimingTest(p,state)
%screenTimingTest    screenTimingTest is a pldaps stimulus to test the physical delay of the onset of a stimulus on the screen to 
%                    to the time the vsync occured. 

% Before running this, you should have made basic sanity checks with
% VBLSyncTest(6000,[],[],[],[],[],[],2); 
% and 
% PerceptualVBLSyncTest
%
% how to use:
% 1. Connect Photodiode to Datapixx
% You need to connect a photodiode to one of the Datapixx analog inputs and
% configure pldaps to record that data, e.g.:
%
% settingsStruct.datapixx.adc.channels=0; % first channel
% settingsStruct.datapixx.adc.channelModes=2; %photodiode ground is
% connected to Ref 0 (0: ground, 1:differential to channelNr+1,
% 2:Differential to Ref0, 3:Differetial to Ref1)
% settingsStruct.datapixx.adc.srate=10000; % 10k, so get 0.1ms precision
% 
% 2. Place Photodiode
% You must place the photodiode in one of 5 locations and set this in the
% settingsStruct accordingly:
%
% settingsStruct.stimulus.location = 1; % 
%
% 1: Top left corner: This is the most important
% location as the frame updating should start here, i.e. it is the best
% estimate of the time of vertical trace reset that be compare it to
% 2: Bottom left corner: On a CRT this should be very close to one
% frame duration later than 1
% 3: Top right corner: Only slightly later than 1 (on CRT)
% 4: Bottom right corner: Position last updated on a CRT
% 5: center left: just one more position that is var from any glitches in
% vsync estimates.
%
% 3. Set Trial Parameters
% settingsStruct.pldaps.maxTrialLength = 3; %Each trial is 3 seconds long.
% The stimulus will only be shown up to 1 second before end of trial trial.
% If you do not set this, this will befault to whatever you have set in
% your rigprefs
% settingsStruct.stimulus.nTrials = 200; %how many measurements?
%
% 4. Analyze
% a simple analysis is included in this. Just call screenTimingTest(p),
% where p is your just recorded pldaps class.
% or turn on online analysis:
% settingsStruct.stimulus.online.analysis = true;
%
% putting it all together:
% settingsStruct.datapixx.adc.channels=0;
% settingsStruct.datapixx.adc.channelModes=2;
% settingsStruct.datapixx.adc.srate=10000; 
% settingsStruct.stimulus.location = 2;
% settingsStruct.pldaps.trialLength = 1.5;
% settingsStruct.stimulus.nTrials = 20; 
% settingsStruct.stimulus.online.analysis = true;
% settingsStruct.eyelink.use=false;
% settingsStruct.mouse.useAsEyepos=true;
% settingsStruct.mouse.use=true;
% settingsStruct.display.bgColor=[0 0 0];
% settingsStruct.pldaps.pause.preExperiment=false;
% name = 'RigAndScreenName';
% p=pldaps(@screenTimingTest, settingsStruct, name);
% p.run
% savefig(gcf,name)


    if nargin==1 && isempty(p.data) %initial call to setup conditions
        
        if ~isField(p.trial,'stimulus.nTrials')
            p.trial.stimulus.nTrials = 200;
        end
        if ~isField(p.trial,'stimulus.location')
            p.trial.stimulus.location = 1;
        end
        
        if ~isField(p.trial,'stimulus.online.analysis')
            p.trial.stimulus.online.analysis = false;
        end
        if ~isField(p.trial,'pldaps.trialLength')
            p.trial.pldaps.trialLength = 3;
        end
        
        p.trial.stimulus.size=5;
        
        sz=p.trial.stimulus.size*p.trial.display.ppd;
        
        p = pdsDefaultTrialStructure(p); 

%         p.trial.pldaps.trialMasterFunction='runTrial';
        p.defaultParameters.pldaps.trialFunction='screenTimingTest';
        %five seconds per trial.
        
        p.trial.pldaps.maxFrames = p.trial.pldaps.trialLength*p.trial.display.frate;
        
        switch p.trial.stimulus.location
            case 1
                rect = [p.trial.display.winRect(1:2) p.trial.display.winRect(1:2)+sz];
            case 2
                rect = [p.trial.display.winRect(1) p.trial.display.winRect(4)-sz ...
                    p.trial.display.winRect(1)+sz p.trial.display.winRect(4)];
            case 3
                rect = [p.trial.display.winRect(3)-sz p.trial.display.winRect(2)...
                    p.trial.display.winRect(3) p.trial.display.winRect(2)+sz];
            case 4
                rect = [p.trial.display.winRect(3:4)-sz p.trial.display.winRect(3:4)];
            case 5
                rect = [p.trial.display.winRect(1) mean(p.trial.display.winRect([2 4]))];
                rect = [rect rect+sz];
            otherwise
                rect = [p.trial.display.winRect(1) p.trial.display.winRect(4)-sz ...
                    p.trial.display.winRect(1)+sz p.trial.display.winRect(4)];
        end
    
        p.trial.stimulus.rect=rect;        
        
        c.Nr=1; %one condition;
        p.conditions=repmat({c},1,p.trial.stimulus.nTrials);

        p.defaultParameters.pldaps.finish = length(p.conditions); 

        defaultTrialVariables(p);
        
        %online analysis
        if p.trial.stimulus.online.analysis
           figure;
           p.functionHandles{end+1}=subplot(4,1,1);
           p.trial.stimulus.online.figureAx1 = length(p.functionHandles);
           
           p.functionHandles{end+1}=subplot(4,1,2);
           p.trial.stimulus.online.figureAx2 = length(p.functionHandles);
           
           p.functionHandles{end+1}=subplot(4,1,3);
           p.trial.stimulus.online.figureAx3 = length(p.functionHandles);
           
%            p.trial.stimulus.online.figureAx1 = subplot(3,1,1);
%            p.trial.stimulus.online.figureAx2 = subplot(3,1,2);
%            p.trial.stimulus.online.figureAx3 = subplot(3,1,3);
        end
        
    elseif nargin==1 %analyse previously recorded data
%         for j=1:length(p.data)
%             d=p.data{j}.datapixx.adc.data;
%             md=median(d);
%             sd=std(d);
%             id=find(abs((d - md)/sd) > 4,1,'first');
%             if ~isempty(id)
%             	pdt(j)=p.data{j}.datapixx.adc.dataSampleTimes(id);
%             else
%             	pdt(j)=NaN;
%             end
% 
%             flipTime(j)=p.data{j}.stimulus.onDatapixxTime;
%         end
% 
%         plot(1000*(pdt-flipTime))
    else
        %if you don't want all the pldapsDefaultTrialFucntions states to be used,
        %just call them in the states you want to use it.
        %otherwise just leave it here
        pldapsDefaultTrialFunction(p,state);
        switch state
            case p.trial.pldaps.trialStates.trialSetup
                p.trial.stimulus.onFrame=randi([1 ceil(p.trial.pldaps.maxFrames-p.trial.display.frate-0.25)]);
%             case p.trial.pldaps.trialStates.trialPrepare
            case p.trial.pldaps.trialStates.trialCleanUpandSave
                if p.trial.iFrame > p.trial.stimulus.onFrame
                    [p.trial.stimulus.onDatapixxTime, p.trial.stimulus.onComputerTimeEstimate] = PsychDataPixx('GetLastOnsetTimestamp'); 
                else
                    p.trial.stimulus.onDatapixxTime = NaN;
                    p.trial.stimulus.onComputerTimeEstimate = NaN;
                end
                d=p.trial.datapixx.adc.data;
                t=p.trial.datapixx.adc.dataSampleTimes;
                md=median(d);
                sd=std(d);
                id=find(abs((d - md)/sd) > 8,1,'first');
                if ~isempty(id)
%                     sd2=std(d(1:id));
%                     id=find(abs((d - md)/sd2) > 4,1,'first');
                    sd2=sd;
                    pdt=t(id);
                else
                    sd2=sd;
                    pdt=NaN;
                end
                
                p.trial.stimulus.photoDiodeDatapixxTime = pdt;
                
                if p.trial.stimulus.online.analysis
                    if ~isempty(p.data)
                        x=cellfun(@(x) x.stimulus.photoDiodeDatapixxTime - x.stimulus.onDatapixxTime,p.data);
                        x(end+1)=pdt-p.trial.stimulus.onDatapixxTime;
                    else
                        x=pdt-p.trial.stimulus.onDatapixxTime;
                    end
                    x=x*1000;

                    ax=p.functionHandles{p.trial.stimulus.online.figureAx1};
                    plot(ax,x);
                    hold(ax, 'on');
                    plot(ax,length(x),pdt,'Color', [0 0.8 0]);
                    hold(ax, 'off');
                    ylim(ax,[max(min(x)*0.9,0.1)  max(max(x)*1.1,1) ]);

                    ax=p.functionHandles{p.trial.stimulus.online.figureAx2};
                    if isnan(p.trial.stimulus.onDatapixxTime)
                        t2=(t-t(1))*1000;
                    else
                        t2=(t-p.trial.stimulus.onDatapixxTime)*1000;
                    end
                    plot(ax,t2,d);
                    hold(ax, 'on');
                    plot(ax,[t2(1) t2(end)],[md md], 'k');
                    plot(ax,[t2(1) t2(end)],[md+sd2 md+sd2], '--k');
                    plot(ax,[t2(1) t2(end)],[md+4*sd2 md+4*sd2], '-.k');
                    plot(ax,[t2(1) t2(end)],[md-sd2 md-sd2], '--k');
                    plot(ax,[t2(1) t2(end)],[md-4*sd2 md-4*sd2], '-.k');

                    if ~isempty(id)
                        plot(ax,[t2(id),t2(id)], [0 d(id)], 'k')
                    end
                    hold(ax, 'off');
                    
                    ax=p.functionHandles{p.trial.stimulus.online.figureAx3};
                    anyft=any(p.trial.timing.frameStateChangeTimes,2);
                    plot(ax,p.trial.timing.frameStateChangeTimes(anyft,:)'*1000);
                    l=cell(size(p.trial.timing.frameStateChangeTimes,1));
                    [l{:}]=deal('');
                    l{p.trial.pldaps.trialStates.frameUpdate}='Update';
                    l{p.trial.pldaps.trialStates.framePrepareDrawing}='PrepareDrawing';
                    l{p.trial.pldaps.trialStates.frameDraw}='Draw';
                    l{p.trial.pldaps.trialStates.frameDrawingFinished}='DrawingFinished';
                    l{p.trial.pldaps.trialStates.frameFlip}='Flip';
                    legend(ax,l(anyft));
                   
                    drawnow
                    shg
                end
                
%             case p.trial.pldaps.trialStates.frameUpdate
%             case p.trial.pldaps.trialStates.framePrepareDrawing; 
            case p.trial.pldaps.trialStates.frameDraw;
%                 Screen('FillRect',  p.trial.display.ptr,[1 1 1],p.trial.stimulus.rect')
                if p.trial.iFrame==p.trial.stimulus.onFrame
                    PsychDataPixx('LogOnsetTimestamps', 1);
%                     Screen('FillRect',  p.trial.display.ptr,[1 1 1]*1.,p.trial.stimulus.rect')
                    Screen('FillRect',  p.trial.display.overlayptr,p.trial.display.clut.red,p.trial.stimulus.rect')
%                 elseif  p.trial.iFrame==p.trial.stimulus.onFrame+1
%                     
                end
%             case p.trial.pldaps.trialStates.frameIdlePreLastDraw;
%             case p.trial.pldaps.trialStates.frameDrawTimecritical;
%             case p.trial.pldaps.trialStates.frameDrawingFinished;
%             case p.trial.pldaps.trialStates.frameIdlePostDraw;
            case p.trial.pldaps.trialStates.frameFlip;   
                if p.trial.iFrame >= p.trial.pldaps.maxFrames
                    p.trial.flagNextTrial=true;
                end
        end
    end