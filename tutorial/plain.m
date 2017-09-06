function p=plain(p,state)
%plain    a plain stimulus file for use with a pldaps class. This file
%         serves both as the expriment setup file and the trial state function
% example:
% load settingsStruct
% p=pldaps(@plain,'demo', settingsStruct);
% p.run
    if nargin==1 %initial call to setup conditions
        
        p = pdsDefaultTrialStructure(p); 

%         p.defaultParameters.pldaps.trialMasterFunction='runTrial';
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
%             case p.trial.pldaps.trialStates.frameUpdate
%             case p.trial.pldaps.trialStates.framePrepareDrawing; 
            case p.trial.pldaps.trialStates.frameDraw
                    Screen('DrawDots', p.trial.display.ptr, randi([-200,200], 2,10), 12, [], p.trial.display.ctr(1:2), 1);
% %             case p.trial.pldaps.trialStates.frameIdlePreLastDraw;
% %             case p.trial.pldaps.trialStates.frameDrawTimecritical;
%             case p.trial.pldaps.trialStates.frameDrawingFinished;
% %             case p.trial.pldaps.trialStates.frameIdlePostDraw;
%
%             case p.trial.pldaps.trialStates.trialSetup
%             case p.trial.pldaps.trialStates.trialPrepare
%             case p.trial.pldaps.trialStates.trialCleanUpandSave

            case p.trial.pldaps.trialStates.frameFlip;   
                if p.trial.iFrame == p.trial.pldaps.maxFrames
                    p.trial.flagNextTrial=true;
                end
        end
    end