function pos = updateFxn(p)
% pos = pds.eyelink.updateFxn(p)
%
%
% %!%!%!% WARNING %!%!%!%
%
%   This method DOES NOT RECORD the timecourse of [sample] data
%   - This fxn is about fast retrieval of current data from tracker
%   - Leaving continuous data recording functions to code specific to
%     tracking source device; e.g. standard eyelink queue polling and
%     p.trial.eyelink.samples.
%
% %!%!%!% WARNING %!%!%!%
%
%
% Get current eye position from eyelink. Updated version of pds.eyelink.getQueue.m for use with
% pds.tracking methods.
% -- Returns only the current position of all eyes tracked; does nothing to [p] structure
% -- Does *not* update p.trial.eyeX as old getQueue function did (...task now resides in pds.tracking.frameUpdate.m)
%
% INPUTS:
%   [p]      Active PLDAPS structure/object
%            - data source will follow p.trial.eyelink.useRawData
%              To ensure data is recoverable with only this .tracking calibration
%              this should really always be set to true (USE RAW DATA!!)
%
% OUTPUT:
%   [pos]    XY position data, as 2-by-nEyes:   eyeL = pos(:,1); eyeR = pos(:,2);
%            -- output shape is clunky elsewhere, but allows blind indexing of "pos(1)" & "pos(2)"
%               to return an X & Y pair, regardless of whether tracking is mono or bino.
%               (scrappy, but occasionally useful...TBD if its worth it)
%
%
% 2013-12-xx  jly  wrote it
% 2014-xx-xx  jk   adapted it for version 4.1
% 2019-12-10  TBC  [re]wrote it.

% Evolved from pds.eyelink.getQueue.m


%% Initialize

useRaw = false;%p.trial.eyelink.useRawData;
% NOTE:  cannot 'useRaw' if mouse simulation mode enabled.
%     useRaw = false;


%% Get data from Eyelink
sample = Eyelink('NewestFloatSample');
if isstruct(sample)
    % Convert [sample] fields to indexable array:
    %   sample fields: [time, type, flags, px, py, hx, hy, pa, gx, gy, rx, ry, status, input, buttons, htype, hdata];
    sample = struct2array(sample)';
else
    % error or no samples available(?)
    pos = [];
    return
end

% NOTE:  No event polling here; only relevant for queued data

%% Parse XY eye position samples
% index tracked eye positions from sample array
eyeIdx = p.trial.eyelink.eyeIdx;
xBase = 3; % samples(14)==left X; samples(15)==right X
yBase = 5; % samples(16)==left Y; samples(17)==right Y

if ~useRaw % default==true
    % Eyelink returns calibrated [gaze] data 10 indices after raw
    xBase = xBase+10;
    yBase = yBase+10;
end

% Index eye sample position(s)
% NOTE: this indexing method will automatically capture both eyes if binocular enabled
%     eyeX = double(sample(eyeIdx+xBase));
%     eyeY = double(sample(eyeIdx+yBase));
%     pos = [eyeX(:), eyeY(:)]';
pos = double( [sample(eyeIdx+xBase), sample(eyeIdx+yBase)] )';


%   % CALIBRATION APPLIED IN  pds.tracking.frameUpdate.m  %


end %main function