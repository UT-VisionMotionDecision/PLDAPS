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
        tic;
        % Construct file name
        edfFile = p.trial.eyelink.edfFile;
        file=p.trial.session.file;
        dirs=p.trial.session.dir;
        filename = fullfile( dirs, 'eye', [file(1:end-3) 'edf']);
        % Get data from Eyelink
        try
            fprintf('Receiving Eyelink data...')
            err = Eyelink('Receivefile',edfFile, filename);
            if err<=0
                warning('pds:EyelinkGetFiles', 'Eyelink file transfer unsuccessful or canceled!');
            else
                fprintf('complete.\n\tEDF file:\t\t%s\n\tfor PDS file:\t%s.\n', filename, file);
            end
        catch
            fprintf('Problem receiving EDF data file ''%s''\n', edfFile );
        end
        fprintf('\t(%3.1f sec to transfer %2.2fMB data from eyelink)\n', toc, err/1e6);
    end
    Eyelink('Shutdown')
end

