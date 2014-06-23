function [Q, rowId] = saveQueue(dv)
% [Q, rowId] = pds.eyelink.saveQueue(dv)
% Prunes unused samples from eyelinksamples and converts them into
% relative time.
% INPUTS:
%       dv.eyelink.samples [31 x nSamples] - from Eyelink('GetQueuedData')
%       dv.eyelink.trackerMode         [string] - remote or headfixed
%       dv.eyelink.EYE_USED            [string] - 'RIGHT', 'LEFT', 'BOTH'
% OUTPUT
%   Q   [double] - n datatypes x n samples
%   rowId [cell] - cell array of strings, name of each row in Q

if nargin < 1
    Eyelink('GetQueuedData?')
    help pds.eyelink.saveQueue
    return
end
    
% 01/2014 jly   wrote it
goodSampleIdx = ~isnan(dv.trial.eyelink.samples(1,:));

% these numbers are hard coded from Eyelink('GetQueuedData')
tmp.time            = dv.trial.eyelink.samples(1,goodSampleIdx);
tmp.sampleType      = dv.trial.eyelink.samples(2,goodSampleIdx);
tmp.LeftPupilSize   = dv.trial.eyelink.samples(12,goodSampleIdx);
tmp.RightPupilSize  = dv.trial.eyelink.samples(13,goodSampleIdx);
tmp.LeftEyeX        = dv.trial.eyelink.samples(14,goodSampleIdx);
tmp.LeftEyeY        = dv.trial.eyelink.samples(16,goodSampleIdx);
tmp.RightEyeX       = dv.trial.eyelink.samples(15,goodSampleIdx);
tmp.RightEyeY       = dv.trial.eyelink.samples(17,goodSampleIdx);

if strcmp(dv.trial.eyelink.trackermode, 'RTABLER')
    for ii = 1:8
        tmpfield = sprintf('HeadTracking%02.0f', ii);
        tmp.(tmpfield) = dv.trial.eyelink.samples(22+ii,goodSampleIdx);
    end
end

switch dv.trial.eyelink.EYE_USED
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