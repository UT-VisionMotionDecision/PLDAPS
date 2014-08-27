function dv=plain(dv,state)

    if(nargin>1) 
        %if you don't want all the pldapsDefaultTrialFucntions states to be used,
        %just call them in the states you want to use it.
        %otherwise just leave it here
        pldapsDefaultTrialFunction(dv,state);
        switch state
%             case dv.trial.pldaps.trialStates.trialSetup
%             case dv.trial.pldaps.trialStates.trialPrepare
%             case dv.trial.pldaps.trialStates.trialCleanUpandSave
%             case dv.trial.pldaps.trialStates.frameUpdate
%             case dv.trial.pldaps.trialStates.framePrepareDrawing; 
%             case dv.trial.pldaps.trialStates.frameDraw;
%             case dv.trial.pldaps.trialStates.frameIdlePreLastDraw;
%             case dv.trial.pldaps.trialStates.frameDrawTimecritical;
%             case dv.trial.pldaps.trialStates.frameDrawingFinished;
%             case dv.trial.pldaps.trialStates.frameIdlePostDraw;
%             case dv.trial.pldaps.trialStates.frameFlip;   
        end
    else%initial call to setup conditions

        dv = pdsDefaultTrialStructure(dv); 

%         dv.defaultParameters.pldaps.trialMasterFunction='runTrial';
        dv.defaultParameters.pldaps.trialFunction='plain';
        dv.trial.stimulus.nframes = 600;
        
        c.Nr=1; %one condition;
        dv.conditions=repmat({c},1,200);

        dv.defaultParameters.pldaps.finish = length(dv.conditions); 

        defaultTrialVariables(dv);
    end
end