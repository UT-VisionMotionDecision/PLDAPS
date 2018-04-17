function p = pmMakeMovie(p, state, sn)
% function p = pmMakeMovie(p, state, sn)
% 
% PLDAPS module ("pm") for capturing & saving a stimulus movie via Screen calls
% 
% 2017-11-21  TBC  Extracted from principle elements of PLDAPS, and modularized.

% %s.	display.	movie.
%  s.	display.	movie.	create = false;
%  s.	display.	movie.	dir = [ ];
%  s.	display.	movie.	file = [ ];
%  s.	display.	movie.	frameRate = [ ];
%  s.	display.	movie.	height = [ ];
%  s.	display.	movie.	options = ':CodecType=x264enc :EncodingQuality=1.0';
%  s.	display.	movie.	width = [ ];

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
            Screen('AddFrameToMovie', p.trial.display.ptr, [], [], p.trial.(sn).ptr, frameDuration);
        end
        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        % Setup movie creation if desired
        setupMovie(p, sn);
        if p.trial.(sn).create
            % Tell Screen what to do
            p.trial.(sn).ptr = Screen('CreateMovie', p.trial.display.ptr, fullfile(p.trial.(sn).dir, [p.trial.(sn).file '.mp4'])...
                , p.trial.(sn).width, p.trial.(sn).height, p.trial.(sn).frameRate, p.trial.(sn).options);
        end

        
    case p.trial.pldaps.trialStates.experimentCleanUp
        % Save the movie file
        if p.trial.(sn).create
            Screen('FinalizeMovie', p.trial.(sn).ptr);
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
        'height', [],...
        'width', [],...
        'options', ':CodecType=x264enc :EncodingQuality=1.0');
    p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
    
end %setupMovie