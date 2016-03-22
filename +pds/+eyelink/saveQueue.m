function [Q, rowId] = saveQueue(p)
%pds.eyelink.saveQueue    prunes unused samples and unneeded fields
%
% [Q, rowId] = pds.eyelink.saveQueue(p)
% Prunes unused samples from eyelinksamples
%
% OUTPUT
%   Q   [double] - n datatypes x n samples
%   rowId [cell] - cell array of strings, name of each row in Q
%
% 01/2014 jly   wrote it
% 2014    jk    adapted for use with version 4.1
if nargin < 1
    Eyelink('GetQueuedData?')
    help pds.eyelink.saveQueue
    return
end
    

goodSampleIdx = ~isnan(p.trial.eyelink.samples(1,:));

% these numbers are hard coded from Eyelink('GetQueuedData')
tmp.time            = p.trial.eyelink.samples(1,goodSampleIdx);
tmp.sampleType      = p.trial.eyelink.samples(2,goodSampleIdx);
tmp.LeftPupilSize   = p.trial.eyelink.samples(12,goodSampleIdx);
tmp.RightPupilSize  = p.trial.eyelink.samples(13,goodSampleIdx);
tmp.LeftEyeX        = p.trial.eyelink.samples(14,goodSampleIdx);
tmp.LeftEyeY        = p.trial.eyelink.samples(16,goodSampleIdx);
tmp.RightEyeX       = p.trial.eyelink.samples(15,goodSampleIdx);
tmp.RightEyeY       = p.trial.eyelink.samples(17,goodSampleIdx);

if p.trial.eyelink.useRawData
    tmp.LeftEyeRawX        = p.trial.eyelink.samples(4,goodSampleIdx);
    tmp.LeftEyeRawY        = p.trial.eyelink.samples(6,goodSampleIdx);
    tmp.RightEyeRawX       = p.trial.eyelink.samples(5,goodSampleIdx);
    tmp.RightEyeRawY       = p.trial.eyelink.samples(7,goodSampleIdx);
end

if strcmp(p.trial.eyelink.trackermode, 'RTABLER')
    for ii = 1:8
        tmpfield = sprintf('HeadTracking%02.0f', ii);
        tmp.(tmpfield) = p.trial.eyelink.samples(22+ii,goodSampleIdx);
    end
end

switch p.trial.eyelink.EYE_USED
    case 'RIGHT'
        tmp = rmfield(tmp, 'LeftEyeX');
        tmp = rmfield(tmp, 'LeftEyeY');
        tmp = rmfield(tmp, 'LeftPupilSize');
        if p.trial.eyelink.useRawData
            tmp = rmfield(tmp, 'LeftEyeRawX');
            tmp = rmfield(tmp, 'LeftEyeRawY');
        end
    case 'LEFT'
        tmp = rmfield(tmp, 'RightEyeX');
        tmp = rmfield(tmp, 'RightEyeY');
        tmp = rmfield(tmp, 'RightPupilSize');
        if p.trial.eyelink.useRawData
            tmp = rmfield(tmp, 'RightEyeRawX');
            tmp = rmfield(tmp, 'RightEyeRawY');
        end
    case 'BOTH'
end

Q = cell2mat(struct2cell(tmp));
rowId = fieldnames(tmp);