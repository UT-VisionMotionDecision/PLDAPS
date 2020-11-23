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
    
    %get them all
    while ~p.trial.eyelink.drained
        if p.trial.eyelink.collectQueue
            [samplesIn, eventsIn, p.trial.eyelink.drained] = Eyelink('GetQueuedData');
        else
            sample = Eyelink('NewestFloatSample');
            if ~isstruct(sample)
                samplesIn = [];
            else
                % Format [sample] fields to match array output of 'GetQueuedData'
                %   sample fields: [time, type, flags, px, py, hx, hy, pa, gx, gy, rx, ry, status, input, buttons, htype, hdata];
                samplesIn = struct2array(sample)';
            end
            eventsIn = [];
            p.trial.eyelink.drained = true;
        end
        % Get Eyelink samples
        if ~isempty(samplesIn)
            % If initialized as singles, these assignments should maintain same class (while taking up half the space; single==full precision of eyelink data)
            p.trial.eyelink.samples(:,(p.trial.eyelink.sampleNum+1):p.trial.eyelink.sampleNum+size(samplesIn,2)) = samplesIn;
            p.trial.eyelink.sampleNum = p.trial.eyelink.sampleNum+size(samplesIn,2);
        end
        
        % Get Eyelink events
        if ~isempty(eventsIn)
            p.trial.eyelink.events(:,(p.trial.eyelink.eventNum+1):p.trial.eyelink.eventNum+size(eventsIn,2)) = eventsIn;
            p.trial.eyelink.eventNum = p.trial.eyelink.eventNum+size(eventsIn,2);
        end
        
        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        if p.trial.eyelink.collectQueue && (~isempty(samplesIn) || ~isempty(eventsIn))
            p.trial.eyelink.drained = false;
        end
        
    end
    p.trial.eyelink.drained = false;
    
    if(p.trial.eyelink.useAsEyepos)
        eyeIdx = p.trial.eyelink.eyeIdx;
        xBase = 13; % samples(14)==left X; samples(15)==right X
        yBase = 15; % samples(16)==left Y; samples(17)==right Y
        if p.trial.eyelink.useRawData
            %the raw data is 10 fields prior to eyelink calibrated [gaze] data
            xBase = xBase-10;
            yBase = yBase-10;
        end
        
        if p.trial.pldaps.eyeposMovAv > 1
            % NOTE: if ~p.trial.eyelink.collectQueue, moving average may span much longer than expected (i.e. N display frames, not N eyelink samples)
            eInds=(p.trial.eyelink.sampleNum-p.trial.pldaps.eyeposMovAv+1):p.trial.eyelink.sampleNum;
            p.trial.eyeX = mean(p.trial.eyelink.samples(eyeIdx+xBase, eInds), 'double');
            p.trial.eyeY = mean(p.trial.eyelink.samples(eyeIdx+yBase, eInds), 'double');
        else
            p.trial.eyeX = double(p.trial.eyelink.samples(eyeIdx+xBase, p.trial.eyelink.sampleNum));
            p.trial.eyeY = double(p.trial.eyelink.samples(eyeIdx+yBase, p.trial.eyelink.sampleNum));
        end
        
        if ~p.trial.tracking.use && p.trial.eyelink.useRawData && ~isempty(p.trial.eyelink.calibration_matrix)
            % Apply separate calibration matrix to each eye (bino compatible)
            for i = 1:numel(p.trial.eyeX)
                eXY = p.trial.eyelink.calibration_matrix(:,:,eyeIdx(i)) * [p.trial.eyeX(i), p.trial.eyeY(i), 1]';
                p.trial.eyeX(i) = eXY(1);
                p.trial.eyeY(i) = eXY(2);
            end
        end
        
        % Also report delta eye position
        nback = p.trial.eyelink.sampleNum + [-1,0];     nback(nback<1) = 1;
        p.trial.eyeDelta = [diff(p.trial.eyelink.samples(eyeIdx+xBase, nback), [], 2),...
            diff(p.trial.eyelink.samples(eyeIdx+yBase, nback), [], 2)];
        
    end
end