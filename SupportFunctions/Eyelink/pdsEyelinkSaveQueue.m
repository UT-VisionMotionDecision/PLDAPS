function [Q, rowId] = pdsEyelinkSaveQueue(dv)
% [Q, rowId] = pdsEyelinkSaveQueue(dv)
% Prunes unused samples from eyelinkSampleBuffer and converts them into
% relative time.
% INPUTS:
%       dv.el.sampleBuffer [31 x nSamples] - from Eyelink('GetQueuedData')
%       dv.el.trackerMode         [string] - remote or headfixed
%       dv.el.EYE_USED            [string] - 'RIGHT', 'LEFT', 'BOTH'
% OUTPUT
%   Q   [double] - n datatypes x n samples
%   rowId [cell] - cell array of strings, name of each row in Q

if nargin < 1
    Eyelink('GetQueuedData?')
    help pdsEyelinkSaveQueue
    return
end
    
% 01/2014 jly   wrote it
goodSampleIdx = ~isnan(dv.el.sampleBuffer(1,:));

% these numbers are hard coded from Eyelink('GetQueuedData')
tmp.time            = dv.el.sampleBuffer(1,goodSampleIdx);
tmp.sampleType      = dv.el.sampleBuffer(2,goodSampleIdx);
tmp.LeftPupilSize   = dv.el.sampleBuffer(12,goodSampleIdx);
tmp.RightPupilSize  = dv.el.sampleBuffer(13,goodSampleIdx);
tmp.LeftEyeX        = dv.el.sampleBuffer(14,goodSampleIdx);
tmp.LeftEyeY        = dv.el.sampleBuffer(16,goodSampleIdx);
tmp.RightEyeX       = dv.el.sampleBuffer(15,goodSampleIdx);
tmp.RightEyeY       = dv.el.sampleBuffer(17,goodSampleIdx);

if strcmp(dv.el.trackermode, 'RTABLER')
    for ii = 1:8
        tmpfield = sprintf('HeadTracking%02.0f', ii);
        tmp.(tmpfield) = dv.el.sampleBuffer(22+ii,goodSampleIdx);
    end
end

switch dv.el.EYE_USED
    case 'RIGHT'
        tmp = rmfield(tmp, 'LeftEyeX');
        tmp = rmfield(tmp, 'LeftEyeY');
        tmp = rmfield(tmp, 'LeftPupilSize');
    case 'LEFT'
        tmp = rmfield(tmp, 'RightEyeX');
        tmp = rmfield(tmp, 'RightEyeY');
        tmp = rmfield(tmp, 'RightPupilSize');
    case 'BOTH'
end

Q = cell2mat(struct2cell(tmp));
rowId = fieldnames(tmp);