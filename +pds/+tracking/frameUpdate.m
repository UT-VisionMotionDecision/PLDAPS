function p = frameUpdate(p)
% p = pds.tracking.frameUpdate(p)
% get current sample from tracked source & apply calibration
%
% 
% %!%!%!% WARNING %!%!%!%
% 
%   This method DOES NOT CURRENTLY RECORD thefull array of [sample] data
%   normally returned in p.trial.eyelink.samples.
%   ....needs more complete coding once functional
% 
% %!%!%!% WARNING %!%!%!%
% 
% 
% p = pds.eyelink.getQueue(p)
% pds.eyelink.getQueue pulls the values from the current Eyelink queue and
% puts them into the p.trial.eyelink struct
%
% 12/2013 jly   wrote it
% 2014    jk    adapted it for version 4.1
% 

if p.trial.tracking.use
    src = p.trial.tracking.source;
    cm = p.trial.(src).calibration_matrix;
    
    % determine if calibration is a matrix or geotransform object (latter preferred)
    isTform = isa(cm(1),'images.geotrans.internal.GeometricTransformation');
    
    % get current position data
    posRaw = feval(p.trial.tracking.updateFxn.(src), p);
    
    % ?? Allow temporal smoothing here?
    %         if p.trial.pldaps.eyeposMovAv > 1
    %             % NOTE: if ~p.trial.eyelink.collectQueue, moving average may span much longer than expected (i.e. N display frames, not N eyelink samples)
    %             eInds=(p.trial.eyelink.sampleNum-p.trial.pldaps.eyeposMovAv+1):p.trial.eyelink.sampleNum;
    %             p.trial.eyeX = mean(p.trial.eyelink.samples(eyeIdx+xBase, eInds), 'double');
    %             p.trial.eyeY = mean(p.trial.eyelink.samples(eyeIdx+yBase, eInds), 'double');
    %         else
    
    % Apply separate calibration matrix to each eye (bino compatible)
    for i = 1:size(posRaw,2)
        if isTform
            pos = transformPointsForward(cm(i), posRaw(:,i)')'; %(1,i), posRaw(2,i));
        else
            eXY = cm(:,:,i) * [posRaw(1,i), posRaw(2,i), 1]';
            pos(1,i) = eXY(1);
            pos(2,i) = eXY(2);
        end
    end
    
    % assign positions to source outputs
    p.trial.tracking.pos = pos;
    p.trial.tracking.posRaw = posRaw;
    % Store tracking timecourse w/in source module
    p.trial.(src).pos(:,p.trial.iFrame) = pos(:);
    p.trial.(src).posRaw(:,p.trial.iFrame) = posRaw(:);
    
    if p.trial.(src).useAsEyepos
        p.trial.eyeX = pos(1,:);
        p.trial.eyeY = pos(2,:);
    end
        
% %         % Also report delta eye position
% %         nback = p.trial.eyelink.sampleNum + [-1,0];     nback(nback<1) = 1;
% %         p.trial.eyeDelta = [diff(p.trial.eyelink.samples(eyeIdx+xBase, nback), [], 2),...
% %             diff(p.trial.eyelink.samples(eyeIdx+yBase, nback), [], 2)];
        
    end
end