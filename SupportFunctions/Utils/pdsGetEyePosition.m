function dv = pdsGetEyePosition(dv)
% dv = pdsGetEyePosition(dv)
% Update eye position
% Inputs: dv struct
%       .trial
%           .cursorX   [1 x 1] - x position of cursor (pixels)
%           .cursorY   [1 x 1] - y position of the cursor (pixels
%       .useEyelink  [boolean] - use the eyelink IP connection
%
% Outputs: dv struct (modified)
%       .trial
%           .eyeX   [1 x 1] - horizontal eye position (pixels)
%           .eyeY   [1 x 1] - vertical eye position (pixels)

% quick sample current position of eye
if dv.useMouse
    dv.trial.eyeX = dv.trial.cursorX;
    dv.trial.eyeY = dv.trial.cursorY;
elseif dv.useEyelink
    % Get Eyelink Queue data
    dv = pdsEyelinkGetQueue(dv);
    if isfield(dv, 'movav')
        try
            
            dv.trial.eyeX = mean(dv.el.sampleBuffer(14,(dv.el.sampleNum-dv.movav):dv.el.sampleNum-1));
            dv.trial.eyeY = mean(dv.el.sampleBuffer(16,(dv.el.sampleNum-dv.movav):dv.el.sampleNum-1));
        catch eyeGetError
            %%% Eyelink toolbox way of sampling the eye position %%%
            eye = Eyelink('getfloatdata', dv.el.SAMPLE_TYPE);
            dv.trial.eyeX = eye.gx(dv.el.eyeIdx);
            dv.trial.eyeY = eye.gy(dv.el.eyeIdx);
            dv.trial.eyeGetError = eyeGetError;
        end
    else
        eye = Eyelink('getfloatdata', dv.el.SAMPLE_TYPE);
        dv.trial.eyeX = eye.gx(dv.el.eyeIdx);
        dv.trial.eyeY = eye.gy(dv.el.eyeIdx);
    end
    
else
    [dv.trial.eyeX, dv.trial.eyeY] = pdsDatapixxGetEyePosition(dv);
end

