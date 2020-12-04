function p = frameUpdate(p)
% p = pds.tracking.frameUpdate(p)
% get current sample from tracked source & apply calibration
% 
% Called during [frameUpdate] state of [pldapsDefaultTrial]
% 
% TODO:  Add explainer for how updateFxn should be constructed for different
% tracker sources.
% 
% %!%!%!% WARNING %!%!%!%
% 
%   This method DOES NOT RECORD thefull array of [sample] data
%   - Continuous data recording functions are left up to 
%     tracking source specific code; e.g. pds.eyelink.getQueue
%
% %!%!%!% WARNING %!%!%!%
% 
% 
% See also:  pds.tracking.runCalibrationTrial, pds.eyelink.updateFxn, pds.mouse.updateFxn
% 
% 
% 2020-01-xx  TBC  Wrote it.

% Evolved from pds.eyelink.getQueue.m


% NO: % if p.trial.tracking.use
%     - this is an old/wasteful convention; if you don't use, don't call outside fxn in first place.

    src = p.trial.tracking.source;
    tform = p.trial.(src).tracking_tform;
    % contents of this should be a geometric transform object,
    
    % Get current position data from tracking source
    posRaw = feval(p.static.tracking.updateFxn.(src), p);

    % NOTE: function handles CANNOT exist in p.trial; they MUST be stored in p.static instead
    %       ...krufty holdover of the 'params' class; nixing it has long been on the TODO list
    
    % Record all frame samples in tracking source
    pos2src = isfield(p.trial.(src),'posFrames');
    
    % Apply separate calibration to each eye (bino compatible)
    for i = 1:size(posRaw,2)
        ii = p.trial.tracking.srcIdx(i);
        
        pos(:,i) = transformPointsInverse(tform(min([ii,end])), posRaw(:,i)')';
        % NOTE:  switched to Inverse from transformPointsForward method
        % because forward method doesn't exist for polynomial class tforms
            
        if pos2src
            p.trial.(src).posFrames(:,i,p.trial.iFrame) = pos(:,i);
            p.trial.(src).posRawFrames(:,i,p.trial.iFrame) = posRaw(:,i);
        end
    end
    
% % %     %Print raw pos to command window while sanity checking
% % %             fprintf(repmat('\b',1,44));
% % %             fprintf('%20.18g,  %20.18g\n', posRaw(1:2));
    
    % assign positions to source outputs
    p.trial.tracking.pos = pos;
    p.trial.tracking.posRaw = posRaw;
    
        
    % Apply calibrated data as current eye position
    if p.trial.(src).useAsEyepos
        p.trial.eyeX = pos(1,:)';
        p.trial.eyeY = pos(2,:)';
    end
                    
end %main function
