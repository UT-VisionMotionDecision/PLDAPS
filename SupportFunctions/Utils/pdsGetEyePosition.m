function dv = pdsGetEyePosition(dv, updateQueue)
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
if dv.trial.mouse.use
    dv.trial.eyeX = dv.trial.cursorX;
    dv.trial.eyeY = dv.trial.cursorY;
elseif dv.trial.eyelink.use
    
    if(nargin<2 || updateQueue || (isfield(dv.trial.eyelink, 'movav') && dv.trial.eyelink.movav>1))
        pds.eyelink.getQueue(dv);
    end
    % Get Eyelink Queue data
    if isfield(dv.trial.eyelink, 'movav') && dv.trial.eyelink.movav>1
        try
            
            dv.trial.eyeX = mean(dv.trial.eyelink.sampleBuffer(14,(dv.trial.eyelink.sampleNum-dv.trial.eyelink.movav):dv.trial.eyelink.sampleNum-1));
            dv.trial.eyeY = mean(dv.trial.eyelink.sampleBuffer(16,(dv.trial.eyelink.sampleNum-dv.trial.eyelink.movav):dv.trial.eyelink.sampleNum-1));
        catch eyeGetError
            %%% Eyelink toolbox way of sampling the eye position %%%
            eye = Eyelink('getfloatdata', dv.trial.eyelink.setup.SAMPLE_TYPE);
            dv.trial.eyeX = eye.gx(dv.trial.eyelink.eyeIdx);
            dv.trial.eyeY = eye.gy(dv.trial.eyelink.eyeIdx);
            dv.trial.eyelink.eyeGetError = eyeGetError;
        end
    else
        eye = Eyelink('getfloatdata', dv.trial.eyelink.setup.SAMPLE_TYPE);
        dv.trial.eyeX = eye.gx(dv.trial.eyelink.eyeIdx);
        dv.trial.eyeY = eye.gy(dv.trial.eyelink.eyeIdx);
    end
    
elseif dv.trial.datapixx.use
    [dv.trial.eyeX, dv.trial.eyeY] = pds.datapixx.getEyePosition(dv);
end

