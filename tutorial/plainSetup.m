function p=plainSetup(p)
%plain    a plain setup file setting up the use of the trial state function
%         plain. While plain.m alreay has this included. A more typical use
%         scenario will have a separate setup file as used here.
% example:
% load settingsStruct
% p=pldaps(@plainSetup,'demo', settingsStruct);
% p.run
    p = pdsDefaultTrialStructure(p); 

%         dv.defaultParameters.pldaps.trialMasterFunction='runTrial';
    p.defaultParameters.pldaps.trialFunction='plain';
        %five seconds per trial.
    p.trial.pldaps.maxTrialLength = 5;
    p.trial.pldaps.maxFrames = p.trial.pldaps.maxTrialLength*p.trial.display.frate;
        
    c.Nr=1; %one condition;
    p.conditions=repmat({c},1,200);

    p.defaultParameters.pldaps.finish = length(p.conditions); 
    defaultTrialVariables(p);
end