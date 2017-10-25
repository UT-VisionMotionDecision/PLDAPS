function p = pdsGetEyePosition(p)
% dv = pdsGetEyePosition(dv)
% Update eye position
% Inputs: p struct
%       .trial
%           .cursorX   [1 x 1] - x position of cursor (pixels)
%           .cursorY   [1 x 1] - y position of the cursor (pixels
%       .useEyelink  [boolean] - use the eyelink IP connection
%
% Outputs: p struct (modified)
%       .trial
%           .eyeX   [1 x 1] - horizontal eye position (pixels)
%           .eyeY   [1 x 1] - vertical eye position (pixels)

% quick sample current position of eye
XMaxSampleCount=subsref(p,p.trial.pldaps.eyepos.XSamplesCountSubs);
YMaxSampleCount=subsref(p,p.trial.pldaps.eyepos.XSamplesCountSubs);

movav=p.trial.pldaps.eyepos.movav;%;=1;

XSampleInds=(XMaxSampleCount-movav:XMaxSampleCount);
XSampleInds(XSampleInds<1)=[];

YSampleInds=(YMaxSampleCount-movav:YMaxSampleCount);
YSampleInds(YSampleInds<1)=[]; 

XSub=p.trial.pldaps.eyepos.XSamplesFieldSubs;
XSub(end).subs{end}=XSampleInds;

YSub=p.trial.pldaps.eyepos.YSamplesFieldSubs;
YSub(end).subs{end}=YSampleInds;

p.trial.eyeX=mean(subsref(p,XSub));
p.trial.eyeY=mean(subsref(p,YSub));
% if p.trial.mouse.use
%     p.trial.eyeX = p.trial.cursorX;
%     p.trial.eyeY = p.trial.cursorY;
% elseif p.trial.eyelink.use
%     
%     if(nargin<2 || updateQueue || (isfield(p.trial.eyelink, 'movav') && p.trial.eyelink.movav>1))
%         pds.eyelink.getQueue(p);
%     end
%     % Get Eyelink Queue data
%     if isfield(p.trial.eyelink, 'movav') && p.trial.eyelink.movav>1
%         try
%             
%             p.trial.eyeX = mean(p.trial.eyelink.sampleBuffer(14,(p.trial.eyelink.sampleNum-p.trial.eyelink.movav):p.trial.eyelink.sampleNum-1));
%             p.trial.eyeY = mean(p.trial.eyelink.sampleBuffer(16,(p.trial.eyelink.sampleNum-p.trial.eyelink.movav):p.trial.eyelink.sampleNum-1));
%         catch eyeGetError
%             %%% Eyelink toolbox way of sampling the eye position %%%
%             eye = Eyelink('getfloatdata', p.trial.eyelink.setup.SAMPLE_TYPE);
%             p.trial.eyeX = eye.gx(p.trial.eyelink.eyeIdx);
%             p.trial.eyeY = eye.gy(p.trial.eyelink.eyeIdx);
%             p.trial.eyelink.eyeGetError = eyeGetError;
%         end
%     else
%         eye = Eyelink('getfloatdata', p.trial.eyelink.setup.SAMPLE_TYPE);
%         p.trial.eyeX = eye.gx(p.trial.eyelink.eyeIdx);
%         p.trial.eyeY = eye.gy(p.trial.eyelink.eyeIdx);
%     end
%     
% elseif p.trial.datapixx.use
%     [p.trial.eyeX, p.trial.eyeY] = pds.datapixx.getEyePosition(p);
% end
% 
