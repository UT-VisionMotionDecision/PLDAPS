function p=eyelinkTimingTest(p,state)
%eyelinkTimingTest    pldaps trial state function to test the time delay of the eyelink system with
%                     the computer
% oversample on datapixx on some large prime number
% run at different eyelink frequencies
% 
% how to use:
% 1. Connect ones eyelinks x channel to Datapixx
% You need to connect the eyelink analog output to one of the Datapixx analog inputs and
% configure pldaps to record that data, e.g.:
%
% settingsStruct.datapixx.adc.channels=[0 1]; % first channel
% settingsStruct.datapixx.adc.channelModes=2; %photodiode ground is
% connected to Ref 0 (0: ground, 1:differential to channelNr+1,
% 2:Differential to Ref0, 3:Differetial to Ref1)
% settingsStruct.datapixx.adc.srate=10000; % 10k, so get 0.1ms precision
% 
% 2. move your eyes
% do a couple of trials a move your eyes around, randomly if possible.
% don't blink
%
% 3. Set Trial Parameters
% settingsStruct.pldaps.maxTrialLength = 3; %Each trial is 3 seconds long.
% The stimulus will only be shown up to 1 second before end of trial trial.
% If you do not set this, this will befault to whatever you have set in
% your rigprefs
% settingsStruct.stimulus.nTrials = 200; %how many measurements?
%
% 4. Analyze
% a simple online analysis is included in this. Turn on online analysis:
% settingsStruct.stimulus.online.analysis = true;
%
% putting it all together:
% settingsStruct.datapixx.adc.channels=[0 1];
% settingsStruct.datapixx.adc.channelModes=2;
% settingsStruct.datapixx.adc.srate=10781; 
% settingsStruct.pldaps.trialLength = 15;
% settingsStruct.stimulus.nTrials = 20; 
% settingsStruct.stimulus.online.analysis = true;
% settingsStruct.eyelink.use=true;
% settingsStruct.pldaps.pause.preExperiment=true; %we want to calibrate
% p=pldaps(@eyelinkTimingTest, settingsStruct, 'RigAndScreenNameAndEyelinkFrequency');
% p.run

    if nargin==1 && isempty(p.data) %initial call to setup conditions
        
        if ~isField(p.trial,'stimulus.nTrials')
            p.trial.stimulus.nTrials = 5;
        end        
        if ~isField(p.trial,'stimulus.online.analysis')
            p.trial.stimulus.online.analysis = false;
        end
        if ~isField(p.trial,'pldaps.trialLength')
            p.trial.pldaps.trialLength = 30;
        end
        
        p = pdsDefaultTrialStructure(p); 

%         dv.trial.pldaps.trialMasterFunction='runTrial';
        p.defaultParameters.pldaps.trialFunction='eyelinkTimingTest';
        
        p.trial.pldaps.maxFrames = p.trial.pldaps.trialLength*p.trial.display.frate;
        
        c.Nr=1; %one condition;
        p.conditions=repmat({c},1,p.trial.stimulus.nTrials);

        p.defaultParameters.pldaps.finish = length(p.conditions); 

        defaultTrialVariables(p);
        
%         %online analysis
        if p.trial.stimulus.online.analysis
           figure;
           p.functionHandles{end+1}=subplot(4,1,1);
           p.trial.stimulus.online.figureAx1 = length(p.functionHandles);
           
           p.functionHandles{end+1}=subplot(4,1,2);
           p.trial.stimulus.online.figureAx2 = length(p.functionHandles);
           
           p.functionHandles{end+1}=subplot(4,1,3);
           p.trial.stimulus.online.figureAx3 = length(p.functionHandles);
           
           p.functionHandles{end+1}=subplot(4,1,4);
           p.trial.stimulus.online.figureAx4 = length(p.functionHandles);
%            p.trial.stimulus.online.figureAx1 = subplot(4,1,1);
%            p.trial.stimulus.online.figureAx2 = subplot(4,1,2);
%            p.trial.stimulus.online.figureAx3 = subplot(4,1,3);
%            p.trial.stimulus.online.figureAx4 = subplot(4,1,4);
        end
        
    elseif nargin==1 %%offline analysis
        %         e=edfmex([p.initialParametersMerged.session.file(1:end-3) 'edf']);
        
        %%
        screenSizeX=diff(PDS.initialParametersMerged.display.winRect([1 3]));
        
        ELtime=cellfun(@(x) x.timing.eyelinkStartTime, p.data, 'UniformOutput', false);
        ELtime=vertcat(ELtime{:})';
        ELfit=[ELtime(2,:); ones(size(ELtime(2,:)))]'\ELtime(1,:)'; 
        EL2PTB=@(x) x*ELfit(1) + ELfit(2);


        DPtime=cellfun(@(x) x.timing.datapixxPreciseTime, p.data, 'UniformOutput', false);
        DPtime=vertcat(DPtime{:})';
        DPfit=[DPtime(2,:); ones(size(DPtime(2,:)))]'\DPtime(1,:)';               
        DP2PTB=@(x) x*DPfit(1) + DPfit(2);
        
        
        for iTrial=1:length(PDS.data)
             %get eyelink data sent over ethernet: Do this for X and Y
            dpDataX=p.data{iTrial}.datapixx.adc.data(1,:);
%             dpDataY=p.data{iTrial}.datapixx.adc.data(2,:);
                       
            dpSampleTimeDP =p.data{iTrial}.datapixx.adc.dataSampleTimes; %el sample Times in EL time
            dpSampleTimePTB=DP2PTB(dpSampleTimeDP);
            if any(diff(dpSampleTimePTB)<0)
               new_start_ind=find(diff(dpSampleTimePTB)<0, 1,'last')+1;
               dpDataX=dpDataX(new_start_ind:end);
%                dpDataY=dpDataY(new_start_ind:end);
               dpSampleTimeDP=dpSampleTimeDP(new_start_ind:end);
               dpSampleTimePTB=dpSampleTimePTB(new_start_ind:end);
            end
            
            elXind=find(~cellfun(@isempty,strfind(p.data{iTrial}.eyelink.sampleIds,'EyeX')),1,'first');
%             elYind=find(~cellfun(@isempty,strfind(p.data{iTrial}.eyelink.sampleIds,'EyeY')),1,'first');
            elDataX=p.data{iTrial}.eyelink.samples(elXind,:)-screenSizeX/2;
%             elDataY=p.data{iTrial}.eyelink.samples(elYind,:);
            elSampleTimeEL =p.data{iTrial}.eyelink.samples(1,:)/1000; %el sample Times in EL time
            elSampleTimePTB=EL2PTB(elSampleTimeEL);
            
            ii=1;
            offsetRange=(-10:0.01:10)/1000;
            rpe=nan(1,length(offsetRange));
            for offset=offsetRange
                dpDataXInt=interp1(dpSampleTimePTB,dpDataX,elSampleTimePTB(51:end-51)+offset,'linear','extrap');
%                 dpDataYInt=interp1(dpSampleTimePTB,dpDataY,elSampleTimePTB(51:end-51)+offset,'linear','extrap');
                elDataXInt=elDataX(51:end-51);

                missingData=dpDataXInt<-4.975 | elDataXInt< -30000;
                x1= [dpDataXInt(~missingData); ones(size(dpDataXInt(~missingData)))]'\elDataXInt(~missingData)';
%                 x2= [dpDataYInt; ones(size(dpDataYInt))]'\elDataY(51:end-51)';

                if offset==0
                    x1_0=x1;
                end

                rpeX = nanmean(abs(elDataXInt(~missingData) - (x1(1)*dpDataXInt(~missingData)+ x1(2))));
%                 rpeY = nanmean(abs(elDataY(51:end-51) - (x2(1)*dpDataYInt + x2(2))));
                %now regress dpDataX against ELDataX and find
                %reconstruction error
                rpe(ii)=rpeX;
%                 rpe(ii)=nanmean([rpeX rpeY]);
                ii=ii+1;
            end
            
            [~,ii2]=min(rpe);
            ii=find(rpe-min(rpe)<0.01*2,1,'first'); 
            %the value 0.01 is handpicked by looking at 
            % hist(diff(rpe), -2:0.001:2);
            % and find width of the distribution around 0 (result of
            % oversampling)
            
            bestLag(iTrial) = offsetRange(ii);
            
            close all
            plot(elDataXInt(~missingData))
            hold all
            plot((x1(1)*dpDataXInt(~missingData)+ x1(2)))

            close all
            plot(offsetRange,rpe);
            hold on;
            plot([offsetRange(ii) offsetRange(ii)], [0 rpe(ii)]);
            plot([offsetRange(ii2) offsetRange(ii2)], [0 rpe(ii2)]);
                
        end
        close all;
        plot(bestLag*1000)
    else
        %if you don't want all the pldapsDefaultTrialFucntions states to be used,
        %just call them in the states you want to use it.
        %otherwise just leave it here
        pldapsDefaultTrialFunction(p,state);
        switch state
%             case p.trial.pldaps.trialStates.trialSetup
%             case dv.trial.pldaps.trialStates.trialPrepare
            case p.trial.pldaps.trialStates.trialCleanUpandSave 
                if p.trial.pldaps.iTrial<2 || ~p.trial.stimulus.online.analysis%p.trial.iTrial>1
                    p.trial.stimulus.bestLag(p.trial.pldaps.iTrial) = NaN;
                    return;
                end
                %get eyelink data sent over ethernet: Do this for X and Y
                elXind=find(~cellfun(@isempty,strfind(p.trial.eyelink.sampleIds,'EyeX')),1,'first');
                elYind=find(~cellfun(@isempty,strfind(p.trial.eyelink.sampleIds,'EyeY')),1,'first');
                elDataX=p.trial.eyelink.samples(elXind,:);
%                 elDataY=p.trial.eyelink.samples(elYind,:);
                elSampleTimeEL =p.trial.eyelink.samples(1,:)/1000; %el sample Times in EL time
                
                ELtime=cellfun(@(x) x.timing.eyelinkStartTime, p.data, 'UniformOutput', false);
                ELtime{end+1}=p.trial.timing.eyelinkStartTime;
                ELtime=vertcat(ELtime{:})';
                ELfit=[ELtime(2,:); ones(size(ELtime(2,:)))]'\ELtime(1,:)';
                    
                EL2PTB=@(x) x*ELfit(1) + ELfit(2);
                elSampleTimePTB = EL2PTB(elSampleTimeEL);
                
                %get eyelink data sent over ethernet: Do this for X and Y
                dpDataX=p.trial.datapixx.adc.data(1,:);
%                 dpDataY=p.trial.datapixx.adc.data(2,:);
                dpSampleTimeDP =p.trial.datapixx.adc.dataSampleTimes; %el sample Times in EL time
                
                DPtime=cellfun(@(x) x.timing.datapixxPreciseTime, p.data, 'UniformOutput', false);
                DPtime{end+1}=p.trial.timing.datapixxPreciseTime;
                DPtime=vertcat(DPtime{:})';
                DPfit=[DPtime(2,:); ones(size(DPtime(2,:)))]'\DPtime(1,:)';
                    
                DP2PTB=@(x) x*DPfit(1) + DPfit(2);
                dpSampleTimePTB = DP2PTB(dpSampleTimeDP);
                
                %now in a loop compare the EL dataset with the DP dataset.
                %We're oversampling in DP, so we will do an interpolation
                %of the datapixx data and get that data with different
                %offsets

                ii=1;
                offsetRange=(-10:0.05:10)/1000;
                rpe=nan(1,length(offsetRange));
                for offset=offsetRange
                    dpDataXInt=interp1(dpSampleTimePTB,dpDataX,elSampleTimePTB(51:end-51)+offset,'linear','extrap');
                %                 dpDataYInt=interp1(dpSampleTimePTB,dpDataY,elSampleTimePTB(51:end-51)+offset,'linear','extrap');
                    elDataXInt=elDataX(51:end-51);

                    missingData=dpDataXInt<-4.975 | elDataXInt< -30000;
                    x1= [dpDataXInt(~missingData); ones(size(dpDataXInt(~missingData)))]'\elDataXInt(~missingData)';
                %                 x2= [dpDataYInt; ones(size(dpDataYInt))]'\elDataY(51:end-51)';

                    if offset==0
                        x1_0=x1;
                    end

                    rpeX = nanmean(abs(elDataXInt(~missingData) - (x1(1)*dpDataXInt(~missingData)+ x1(2))));
                %                 rpeY = nanmean(abs(elDataY(51:end-51) - (x2(1)*dpDataYInt + x2(2))));
                    %now regress dpDataX against ELDataX and find
                    %reconstruction error
                    rpe(ii)=rpeX;
                %                 rpe(ii)=nanmean([rpeX rpeY]);
                    ii=ii+1;
                end
                
%                 [~,ii2]=min(rpe);
                ii=find(rpe-min(rpe)<0.01*2,1,'first'); 
                %the value 0.01 is handpicked by looking at 
                % hist(diff(rpe), -2:0.001:2);
                % and find width of the distribution around 0 (result of
                % oversampling)
                p.trial.stimulus.bestLag = offsetRange(ii);
                
                ax=p.functionHandles{p.trial.stimulus.online.figureAx1};
                x=cellfun(@(x) x.stimulus.bestLag,p.data);
                x(end+1)= p.trial.stimulus.bestLag;
                plot(ax,x);

                ax=p.functionHandles{p.trial.stimulus.online.figureAx2};
                plot(ax,dpSampleTimePTB,dpDataX*x1_0(1) + x1_0(2));
                hold(ax, 'all');
                plot(ax,elSampleTimePTB,elDataX);
                legend(ax,{'DataPixx','Eyelink'});
                hold(ax, 'off');
                
                ax=p.functionHandles{p.trial.stimulus.online.figureAx3};
                plot(ax,offsetRange,rpe)
                hold on;
                plot([offsetRange(ii) offsetRange(ii)], [0 rpe(ii)]);
                
                ax=p.functionHandles{p.trial.stimulus.online.figureAx4};
                anyft=any(p.trial.timing.frameStateChangeTimes,2);
                plot(ax,p.trial.timing.frameStateChangeTimes(anyft,:)'*1000);
                l=cell(size(p.trial.timing.frameStateChangeTimes,1));
                [l{:}]=deal('');
                l{p.trial.pldaps.trialStates.frameUpdate}='Update';
                l{p.trial.pldaps.trialStates.framePrepareDrawing}='fPrepareDrawing';
                l{p.trial.pldaps.trialStates.frameDraw}='Draw';
                l{p.trial.pldaps.trialStates.frameDrawingFinished}='DrawingFinished';
                l{p.trial.pldaps.trialStates.frameFlip}='Flip';
                legend(ax,l(anyft));
                hold(ax, 'off');
                  
                drawnow
                shg
                
            case p.trial.pldaps.trialStates.frameFlip;   
                if p.trial.iFrame >= p.trial.pldaps.maxFrames
                    p.trial.flagNextTrial=true;
                end
        end
    end