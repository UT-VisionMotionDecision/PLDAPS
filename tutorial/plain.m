function p=plain(p,state)
%plain    a plain stimulus file for use with a pldaps class. This file
%         serves both as the expriment setup file and the trial state function
% example:
% load settingsStruct
% p=pldaps(@plain,'demo', settingsStruct);
% p.run
    if nargin==1 %initial call to setup conditions
        
        p = pdsDefaultTrialStructure(p); 

%         dv.defaultParameters.pldaps.trialMasterFunction='runTrial';
        p.defaultParameters.pldaps.trialFunction='plain';
        %five seconds per trial.
        p.trial.pldaps.maxTrialLength = 5;
        p.trial.pldaps.maxFrames = p.trial.pldaps.maxTrialLength*p.trial.display.frate;
        
        c.Nr=1; %one condition;
        p.conditions=repmat({c},1,200);

        p.defaultParameters.pldaps.finish = length(p.conditions); 
    else
        %if you don't want all the pldapsDefaultTrialFucntions states to be used,
        %just call them in the states you want to use it.
        %otherwise just leave it here
        pldapsDefaultTrialFunction(p,state);
        switch state
%             case dv.trial.pldaps.trialStates.frameUpdate
%             case dv.trial.pldaps.trialStates.framePrepareDrawing; 
%             case dv.trial.pldaps.trialStates.frameDraw;
% %             case dv.trial.pldaps.trialStates.frameIdlePreLastDraw;
% %             case dv.trial.pldaps.trialStates.frameDrawTimecritical;
%             case dv.trial.pldaps.trialStates.frameDrawingFinished;
% %             case dv.trial.pldaps.trialStates.frameIdlePostDraw;
%
%             case dv.trial.pldaps.trialStates.trialSetup
%             case dv.trial.pldaps.trialStates.trialPrepare
%             case dv.trial.pldaps.trialStates.trialCleanUpandSave

            case p.trial.pldaps.trialStates.frameFlip;   
                if p.trial.iFrame == p.trial.pldaps.maxFrames
                    p.trial.flagNextTrial=true;
                end
        end
    end