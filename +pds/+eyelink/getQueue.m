function p = getQueue(p)
%pds.eyelink.getQueue    get data samples from eyelink
%
% p = pds.eyelink.getQueue(p)
% pds.eyelink.getQueue pulls the values from the current Eyelink queue and
% puts them into the p.trial.eyelink struct
%
% 12/2013 jly   wrote it
% 2014    jk    adapted it for version 4.1
if p.trial.eyelink.use
    % if time to pull samples, get them all
    while ~p.trial.eyelink.drained
        [p.trial.eyelink.samplesIn, p.trial.eyelink.eventsIn, p.trial.eyelink.drained] = Eyelink('GetQueuedData');
        
        % Get Eyelink samples
        if ~isempty(p.trial.eyelink.samplesIn)
            p.trial.eyelink.samples(:,(p.trial.eyelink.sampleNum+1):p.trial.eyelink.sampleNum+size(p.trial.eyelink.samplesIn,2)) = p.trial.eyelink.samplesIn;
            p.trial.eyelink.sampleNum = p.trial.eyelink.sampleNum+size(p.trial.eyelink.samplesIn,2);
        end
        
        % Get Eyelink events
        if ~isempty(p.trial.eyelink.eventsIn)
            p.trial.eyelink.events(:,(p.trial.eyelink.eventNum+1):p.trial.eyelink.eventNum+size(p.trial.eyelink.eventsIn,2)) = p.trial.eyelink.eventsIn;
            p.trial.eyelink.eventNum = p.trial.eyelink.eventNum+size(p.trial.eyelink.eventsIn,2);
        end
        
        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        if ~isempty(p.trial.eyelink.samplesIn) || ~isempty(p.trial.eyelink.eventsIn)
            p.trial.eyelink.drained = false;
        end
        
    end
   p.trial.eyelink.drained = false;
   
   if(p.trial.eyelink.useAsEyepos) 
       if p.trial.pldaps.eyeposMovAv > 1
           eInds=(p.trial.eyelink.sampleNum-p.trial.pldaps.eyeposMovAv+1):p.trial.eyelink.sampleNum;
           p.trial.eyeX = mean(p.trial.eyelink.samples(14,eInds));
           p.trial.eyeY = mean(p.trial.eyelink.samples(16,eInds));
       else
           p.trial.eyeX = p.trial.eyelink.samples(14,p.trial.eyelink.sampleNum);
           p.trial.eyeY = p.trial.eyelink.samples(16,p.trial.eyelink.sampleNum);
       end
   end
end