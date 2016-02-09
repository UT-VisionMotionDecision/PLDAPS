function [] = leap(p,state)
    
    switch state
        
        case p.trial.pldaps.trialStates.frameUpdate;
            frameUpdate(p);
                
        case p.trial.pldaps.trialStates.trialCleanUpandSave;
            cleanUpAndSave(p);
        
        case p.trial.pldaps.trialStates.trialSetup;
            trialSetup(p);    
    end

end


function []= trialSetup(p)
    
    [p.trial.leap.origin,p.trial.leap.succ] = getRawCoords();
    p.trial.leap.origin=[0;250;0];
    p.trial.leap.succ=1
    if ~p.trial.leap.succ
        p.trial.state = p.trial.stimulus.states.NOCURSORINPUT;
    end
    
    p.trial.leap.cursorSamples = nan(3,round(round(p.trial.pldaps.maxFrames*1.1)));
    p.trial.leap.samplesTimes=nan(1,round(round(p.trial.pldaps.maxFrames*1.1)));
    p.trial.leap.samples = 0;
    
    

end


function []= frameUpdate(p)

    [pos,p.trial.leap.succ] = getRawCoords();
    p.trial.leap.samples = p.trial.leap.samples+1;
    p.trial.leap.samplesTimes(p.trial.leap.samples)=GetSecs;
    p.trial.leap.cursorSamples(1:3,p.trial.leap.samples) = pos-p.trial.leap.origin;
    if ~p.trial.leap.succ
        p.trial.state = p.trial.stimulus.states.NOCURSORINPUT;
    end

end

function [] = cleanUpAndSave(p)

    p.trial.leap.cursorSamples(:,p.trial.leap.samples+1:end) = [];
    p.trial.leap.samplesTimes(:,p.trial.leap.samples+1:end) = [];

end

function [pos,succ] = getRawCoords()
    pos = [NaN;NaN;NaN];
    succ = true;
    try
        f = pds.leap.matleapmaster.matleap(1);
        x = f.pointables(1).position(1);
        y = f.pointables(1).position(2);
        z = f.pointables(1).position(3);
        pos = [x;y;z];
    catch
        succ = false;
    end
end

