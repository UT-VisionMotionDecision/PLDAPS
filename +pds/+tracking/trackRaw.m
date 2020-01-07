function p = trackRaw(p)
% undo calibration matrix for whichever input module was used as the tracking source
% store raw in p.trial.tracking.raw(p.trial.iFrame, :)

if p.trial.eyelink.use && p.trial.eyelink.useAsEyepos && p.trial.eyelink.useRawData
    if ~isfield(p.trial.eyelink, 'eyeIdx')
        eyeIdx = 1;
    else
        eyeIdx=p.trial.eyelink.eyeIdx;
    end
    C = p.trial.eyelink.calibration_matrix(:,:,eyeIdx);
    for i = 1:numel(eyeIdx)
        ci = C(:,:,i);
        % C = p.trial.eyelink.calibration_matrix(:,:,i)';
        % raw =  p.trial.eyeX(:,p.trial.iFrame);
        raw = [p.trial.eyeX(i), p.trial.eyeY(i)]';
        
        % undo offset
        raw(1) = raw(1) - ci(3,1);
        raw(2) = raw(2) - ci(3,2);
        % undo gains / rotation
        raw = ci(1:2,1:2)\raw;
        raw = raw'; % ?
        
        % store raw
        p.trial.tracking.raw(1,i) = raw(1);
        p.trial.tracking.raw(2,i) = raw(2);
        % p.trial.calibration.adjustment.raw(p.trial.iFrame,:) = [raw 1];
    end
end

% % %     if p.trial.arrington.use && p.trial.arrington.useAsEyepos
% % %         error('Not implemented')
% % %     end
% % % 
% % %     if p.trial.ddpi.use && p.trial.arrington.useAsEyepos
% % %         error('Not implemented')
% % %     end

% re-apply calibration
if p.trial.iFrame > 1
    p.trial.calibration.adjustment.xy = p.trial.calibration.adjustment.raw(1:p.trial.iFrame-1,:)*p.trial.calibration.adjustment.C;
end
    
return
% %% debug
% 
% if ~isfield(p.trial.eyelink, 'eyeIdx')
%     eyeIdx = 1;
% else
%     eyeIdx=p.trial.eyelink.eyeIdx;
% end
% C = p.trial.eyelink.calibration_matrix(:,:,eyeIdx)';
% raw =  p.trial.behavior.eyeAtFrame(:,1:p.trial.iFrame);
% raw(1,:) = raw(1,:) - C(3,1);
% raw(2,:) = raw(2,:) - C(3,2);
% raw = C(1:2,1:2)\raw;
% raw = raw';
% % raw = raw'*inv(C(1:2,1:2));
% xy = [raw ones(p.trial.iFrame,1)]*p.trial.calibration.adjustment.C;
%     
% figure(1); clf
% plot(p.trial.behavior.eyeAtFrame'); hold on
% % plot(raw)
% % plot(xy, '.')
% plot(p.trial.calibration.adjustment.xy, 'o')
