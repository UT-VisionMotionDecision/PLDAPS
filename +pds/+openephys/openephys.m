function p=openephys(p,state,name)
%openephys     send experiment information to an open-ephys network source
        switch state
            
            case dv.trial.pldaps.trialStates.experimentPostOpenScreen
            %experiment setup

            %make sure we have access to zeroMQ
            if ~exist('zeroMQwrapper')==3 %#ok<EXIST>
                error('pds:openephys','zeroMQwrapper not found. Get the wrapper at https://github.com/open-ephys/GUI/tree/master/Resources/Matlab and add the mex file to your Matlab path');
            end
            %
            p.trial.(name).address='theIP';
            p.trial.(name).protocol='tcp';
            p.trial.(name).port='5556';
            url=sprintf('%s://%s:%s',p.trial.(name).protocol, p.trial.(name).adress, p.trial.(name).port);
            p.trial.(name).handle = zeroMQwrapper('StartConnectThread',url);

            %send our filename
            handle=p.trial.(name).handle;
            zeroMQwrapper('Send',handle ,sprintf('PLDAPS newExperiment File %s',p.defaultParameters.session.file));
            zeroMQwrapper('Send',handle ,sprintf('PLDAPS newExperiment Dir %s',p.defaultParameters.session.dir));
            zeroMQwrapper('Send',handle ,sprintf('PLDAPS newExperiment Setupfile %s',p.defaultParameters.session.experimentSetupFile));
            
%             %implement: way to make this easily, just as strings?
%             zeroMQwrapper('Send',handle ,'ClearDesign');
%             zeroMQwrapper('Send',handle ,'NewDesign nGo_Left_Right');
%             zeroMQwrapper('Send',handle ,'AddCondition Name GoRight TrialTypes 1 2 3');
%             zeroMQwrapper('Send',handle ,'AddCondition Name GoLeft TrialTypes 4 5 6');

            case dv.trial.pldaps.trialStates.experimentCleanUp
            %experiment cleanUp
            handle=p.trial.(name).handle;
            zeroMQwrapper('Send',handle ,sprintf('PLDAPS endExperiment File %s',p.defaultParameters.session.file));
            zeroMQwrapper('CloseThread',handle);
            
            case dv.trial.pldaps.trialStates.trialSetup
                %send trialStart condition
                %send trialNrStart trial number
                handle=p.trial.(name).handle;
%                 zeroMQwrapper('Send',handle ,'TrialStart 2'); 
                zeroMQwrapper('Send',handle ,sprintf('PLDAPS TrialNr %i Start', p.trial.iFrame)); 
                zeroMQwrapper('Send',handle ,sprintf('PLDAPS unique_number %s',p.trial.unique_number)); 
                
                
                
%             case dv.trial.pldaps.trialStates.trialPrepare
            case dv.trial.pldaps.trialStates.trialCleanUpandSave
                %send TrialEnd condition
                %send trialNrEnd number
                handle=p.trial.(name).handle;
                zeroMQwrapper('Send',handle ,sprintf('PLDAPS TrialNr %i End', p.trial.iFrame)); 
%                 zeroMQwrapper('Send',handle ,'TrialEnd 2'); 

                %implement: send trialOutcome....
                
%not  implemented               
%             case dv.trial.pldaps.trialStates.frameUpdate
%             case dv.trial.pldaps.trialStates.framePrepareDrawing; 
%             case dv.trial.pldaps.trialStates.frameDraw;
% %             case dv.trial.pldaps.trialStates.frameIdlePreLastDraw;
% %             case dv.trial.pldaps.trialStates.frameDrawTimecritical;
%             case dv.trial.pldaps.trialStates.frameDrawingFinished;
% %             case dv.trial.pldaps.trialStates.frameIdlePostDraw;
%             case p.trial.pldaps.trialStates.frameFlip;   
%

        end
    end