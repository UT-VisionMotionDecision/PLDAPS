function pos = updateFxn_selfGenerating(eyeIdx, useRaw)
% pos = pds.eyelink.updateFxn(p, useRaw)
% 
% 
% %!%!%!% WARNING %!%!%!%
% 
% ~~~~~~~~~~
% YES!  (And shti)
%   Discovered major problem with function handles inside the p.trial struct (i.e. params class struct)
%   is the fact that most such cases involve functions that take the PLDAPS object as input  (e.g.  out = fxn(p, stuff);)
%   Result is that the function handle workspace includes its own [giant] copy of the pldaps object, and/or
%   all variable access within it must also call all the klunky params struct heirarchy referencing code.
% 
%   Function handles that take simple/numeric inputs are just fine as function handles inside of p.trial
%   
%   Method of self generating function handle with inputs employed in this code works, but is another layer of
%   krufty hacky implementation, and not a reasonable to ask for future users to implement on their own.
% 
%   MUST GET RID OF PARAMS CLASS!!!!
% 
%   TBC 2020-01-09
% ~~~~~~~~~~
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
%   [useRaw] Logical flag (default==true). if useRaw==false, will index to calibrated 'gaze' data
% 
% OUTPUT:
%   [pos]    XY position data, as 2-by-nEyes:   eyeL = pos(:,1); eyeR = pos(:,2);
%            -- format is clunky elsewhere, but allows blind indexing of "pos(1)" & "pos(2)"
%               to return an X & Y pair, regardless of whether tracking is mono or bino.
%               (scrappy, but occasionally useful...TBD if its worth it)
% 
%
% 2013-12-xx  jly  wrote it
% 2014-xx-xx  jk   adapted it for version 4.1
% 2019-12-10  TBC  [re]wrote it.

% Evolved from pds.eyelink.getQueue.m

% Initialize
pos = [];

% Initialize
if nargin<1
    % reach up to caller and retrieve necessary inputs from PLDAPS struct
    fxnInputs = evalin('caller', '{p.trial.eyelink.eyeIdx}');
    if isempty(fxnInputs)
        fxnInputs = -1;
    end
    % return a handle to this function with those inputs
    pos = eval(sprintf('@()pds.eyelink.updateFxn(%d, 1)', fxnInputs{1}));
    
else

% if p.trial.eyelink.use
    % default to use raw data (calibration is applied later by pds.tracking functions)
    if nargin<2 || isempty(useRaw)
        useRaw = 1; 
    end
%     useRaw = false; % NOTE:  cannot 'useRaw' if mouse simulation mode enabled.
    
    sample = Eyelink('NewestFloatSample');
    if isstruct(sample)
        % Convert [sample] fields to indexable array:
        %   sample fields: [time, type, flags, px, py, hx, hy, pa, gx, gy, rx, ry, status, input, buttons, htype, hdata];
        sample = struct2array(sample)';
    else
        % error or no samples available(?)
        % leave pos empty & return
        return
    end
    
    % NOTE:  No event polling here; only relevant for queued data
            
    % index tracked eye positions from sample array
% FIRST INPUT %     eyeIdx = p.trial.eyelink.eyeIdx;
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
    % pos = [pos, pos+15];
    
    %   % CALIBRATION NOW APPLIED IN  pds.tracking.frameUpdate.m  %
    %     if p.trial.eyelink.useRawData
    %         % Apply separate calibration matrix to each eye (bino compatible)
    %         for i = 1:numel(p.trial.eyeX)
    %             eXY = p.trial.eyelink.calibration_matrix(:,:,eyeIdx(i)) * [p.trial.eyeX(i), p.trial.eyeY(i), 1]';
    %             p.trial.eyeX(i) = eXY(1);
    %             p.trial.eyeY(i) = eXY(2);
    %         end
    %     end
                
end


end %main function