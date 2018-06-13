function p = pmSessionMovie(p, state, sn)
% function p = pmMakeMovie(p, state, sn)
% 
% PLDAPS module ("pm") for capturing & saving a stimulus movie via Screen calls
% 
% Defaults:
%  p.trial.(sn).   create = false;
%  p.trial.(sn).   dir = p.trial.session.dir;
%  p.trial.(sn).   file = p.trial.session.file(1:end-4);
%  p.trial.(sn).   frameRate = p.trial.display.frate;
%  p.trial.(sn).   rect = []; % full-screen
%  p.trial.(sn).   options = ':CodecType=x264enc :EncodingQuality=1.0';
% 
% NOTE: During movie capture, Screen only uses the top left corner of the .rect
% parameter is used for image capture; the width & height of each frame is computed
% from p.trial.(sn).rect during initial movie file creation (experimentPostOpenScreen).
% 
% 2017-11-21  TBC  Extracted from principle elements of PLDAPS, and modularized.
% 2018-06-07  TBC  stereoMode friendly, specify 'frontBuffer'
% 

switch state
        
    case p.trial.pldaps.trialStates.frameFlip
        if p.trial.display.frate > p.trial.(sn).frameRate
            % downsample frames
            thisframe = mod(p.trial.iFrame, p.trial.display.frate/p.trial.(sn).frameRate)>0;
        else
            thisframe = true;
        end
        if thisframe
            frameDuration = 1;
            for i = p.trial.display.bufferIdx+1
                if p.trial.display.stereoMode>0
                    Screen('SelectStereoDrawBuffer', p.trial.display.ptr, i-1);
                    % Silly to hardcode this on each frame, but frame drops are inevitable while saving movies anyway...
                    bufferName = {'frontBuffer', 'frontBuffer'};
                else
                    bufferName = {'frontBuffer'};
                end
                Screen('AddFrameToMovie', p.trial.display.ptr, p.trial.(sn).rect, bufferName{i}, p.trial.(sn).ptr(i), frameDuration);
            end
        end
        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        % Setup movie creation if desired
        setupMovie(p, sn);
        if p.trial.(sn).create
            % Width & height from .rect param (default to full screen)
            % Initialize movie file
            for i = p.trial.display.bufferIdx+1
                filename = fullfile(p.trial.(sn).dir, sprintf('%s_%02d.mp4', p.trial.(sn).file, i));
                p.trial.(sn).ptr(i) = Screen('CreateMovie', p.trial.display.ptr, filename...
                    , p.trial.(sn).width, p.trial.(sn).height, p.trial.(sn).frameRate, p.trial.(sn).options);
            end
        end

        
    case p.trial.pldaps.trialStates.experimentCleanUp
        % Save the movie file
        if p.trial.(sn).create
            for i = p.trial.display.bufferIdx+1
                Screen('FinalizeMovie', p.trial.(sn).ptr(i));
            end
        end
        

end

end %pldapsMovie


% % % % % % % % % %
% % Sub-functions
% % % % % % % % % %
%% setupMovie
function p = setupMovie(p, sn)
    % Defaults
    def = struct(...
        'create', false,...
        'file', p.trial.session.file(1:end-4),...
        'dir', p.trial.session.dir,...
        'frameRate', p.trial.display.frate,...
        'rect', [],...
        'options', ':CodecType=x264enc :EncodingQuality=1.0');
    p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);

    if isempty(p.trial.(sn).rect)
        p.trial.(sn).width = p.trial.display.pWidth;
        p.trial.(sn).height = p.trial.display.pHeight;
    else
        p.trial.(sn).width = diff(p.trial.(sn).rect([1,3]));
        p.trial.(sn).height = diff(p.trial.(sn).rect([2,4]));
    end

end %setupMovie