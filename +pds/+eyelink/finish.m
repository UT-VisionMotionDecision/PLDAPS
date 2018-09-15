function p = finish(p)
%pds.eyelink.finish    stop recording on eyelink
%
% p = pds.eyelink.Finish(p)
% pds.eyelink.finish stops recording and closes the currently open edf file.

if nargin < 1
    help pds.eyelink.finish
    return;
end

if p.trial.eyelink.use && Eyelink('IsConnected')
    Eyelink('StopRecording');
    Eyelink('CloseFile');

    % Save EDF file locally
    if p.trial.eyelink.saveEDF
        % Construct file name
        edfFile = p.trial.eyelink.edfFile;
        file=p.trial.session.file;
        dirs=p.trial.session.dir;
        filename = fullfile( dirs, 'eye', [file(1:end-3) 'edf']);
        % Get data from Eyelink
        try
           err = Eyelink('Receivefile',edfFile, filename);
           if err<=0
              warning('pds:EyelinkGetFiles', ['Receiving ' edfFile '.edf for pds file ' file ' unsuccessful or canceled!']);
           else
               fprintf('EDF file received:\t%s\n\tfor pds file: %s.', filename, file);
           end
        catch
            fprintf('Problem receiving EDF data file ''%s''\n', edfFile );
        end
    end
    Eyelink('Shutdown')
end

