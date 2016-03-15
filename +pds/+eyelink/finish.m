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
    % edfFile = fullfile(dv.el.edfFileLocation, dv.el.edfFile);
    edfFile = p.trial.eyelink.edfFile;
    file=p.trial.session.file;
    dirs=p.trial.session.dir;
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    % download data file
    if p.trial.eyelink.saveEDF
        try
           result=Eyelink('Receivefile',edfFile, fullfile(dirs,[file(1:end-3) 'edf']));
           if(result==-1)
              warning('pds:EyelinkGetFiles', ['receiving ' edfFile '.edf for pds file ' file ' failed!']);
           else
               display(['EDF file received: ' edfFile '.edf for pds file ' file '.']);
           end
        catch rdf
            fprintf('Problem receiving EDF data file ''%s''\n', edfFile );
        end
    end
    Eyelink('Shutdown')
end

