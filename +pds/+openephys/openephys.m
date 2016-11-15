function p=openephys(p,state,name)
%openephys     send experiment information to an open-ephys network source
        switch state
            
            case p.trial.pldaps.trialStates.experimentPostOpenScreen
            %experiment setup

            %make sure we have access to zeroMQ
            if ~exist('zeroMQrr')==3 %#ok<EXIST>
                error('pds:openephys','zeroMQrr not found. Get the wrapper at https://github.com/open-ephys/plugin-GUI/tree/master/Resources/Matlab and add the mex file to your Matlab path');
            end
            %
            p.trial.(name).address='100.2.1.1';
            p.trial.(name).protocol='tcp';
            p.trial.(name).port='5556';
            p.trial.(name).url=sprintf('%s://%s:%s',p.trial.(name).protocol, p.trial.(name).address, p.trial.(name).port);
%             p.trial.(name).url = zeroMQrr('StartConnectThread',url);

            %send our filename
            url=p.trial.(name).url;
            zeroMQrr('Send',url ,sprintf('PLDAPS newExperiment File %s',p.defaultParameters.session.file));
            zeroMQrr('Send',url ,sprintf('PLDAPS newExperiment Dir %s',p.defaultParameters.session.dir));
            zeroMQrr('Send',url ,sprintf('PLDAPS newExperiment Setupfile %s',p.defaultParameters.session.experimentSetupFile));
            
            
            p.trial.(name).status.acquiring = zeroMQrr('Send',url ,'IsAcquiring',1);
            p.trial.(name).status.recording = zeroMQrr('Send',url ,'IsRecording',1);
            if(p.trial.(name).status.recording)
                p.trial.(name).status.recordingPath = zeroMQrr('Send',url ,'GetRecordingPath',1);
                p.trial.(name).status.recordingNumber = zeroMQrr('Send',url ,'getRecordingNumber',1);
                p.trial.(name).status.experimentNumber = zeroMQrr('Send',url ,'getExperimentNumber',1);
            else
                p.trial.(name).status.recordingPath = '';
                p.trial.(name).status.recordingNumber = NaN;
                p.trial.(name).status.experimentNumber = NaN;
            end
%             %implement: way to make this easily, just as strings?
%             zeroMQrr('Send',url ,'ClearDesign');
%             zeroMQrr('Send',url ,'NewDesign nGo_Left_Right');
%             zeroMQrr('Send',url ,'AddCondition Name GoRight TrialTypes 1 2 3');
%             zeroMQrr('Send',url ,'AddCondition Name GoLeft TrialTypes 4 5 6');

            case p.trial.pldaps.trialStates.experimentCleanUp
            %experiment cleanUp
            url=p.trial.(name).url;
            zeroMQrr('Send',url ,sprintf('PLDAPS endExperiment File %s',p.defaultParameters.session.file),1);
            zeroMQrr('CloseThread',url);
            [tmp]=zeroMQrr('GetResponses');
            
            case p.trial.pldaps.trialStates.trialSetup
                %send trialStart condition
                %send trialNrStart trial number
                url=p.trial.(name).url;
%                 zeroMQrr('Send',url ,'TrialStart 2'); 
                zeroMQrr('Send',url ,sprintf('PLDAPS TrialNr %i Start', p.trial.pldaps.iTrial)); 
                
                
                
%             case p.trial.pldaps.trialStates.trialPrepare
            case p.trial.pldaps.trialStates.trialCleanUpandSave
                %send TrialEnd condition
                %send trialNrEnd number
                url=p.trial.(name).url;
                zeroMQrr('Send',url ,sprintf('PLDAPS unique_number %i %i %i %i %i %i', p.trial.unique_number)); 
                zeroMQrr('Send',url ,sprintf('PLDAPS TrialNr %i End', p.trial.pldaps.iTrial)); 
                %for now we just flush everything
                [tmp]=zeroMQrr('GetResponses');
%                 zeroMQrr('Send',url ,'TrialEnd 2'); 

                %implement: send trialOutcome....
                
%not  implemented               
%             case p.trial.pldaps.trialStates.frameUpdate
%             case p.trial.pldaps.trialStates.framePrepareDrawing; 
%             case p.trial.pldaps.trialStates.frameDraw;
% %             case p.trial.pldaps.trialStates.frameIdlePreLastDraw;
% %             case p.trial.pldaps.trialStates.frameDrawTimecritical;
%             case p.trial.pldaps.trialStates.frameDrawingFinished;
% %             case p.trial.pldaps.trialStates.frameIdlePostDraw;
%             case p.trial.pldaps.trialStates.frameFlip;   
%

        end
    end