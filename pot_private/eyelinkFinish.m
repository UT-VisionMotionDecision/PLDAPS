function dv = eyelinkFinish(dv)
% dv = pdsEyelinkFinish(dv)
% EyelinkFinish stops recording and closes the currently open edf file.
% dv [strut]



if nargin < 1
    help pdsEyelinkFinish
    return;
end
% if ~isfield(dv.disp, 'saveEDF')
%     dv.disp.saveEDF = 0;
% end

if dv.defaultParameters.eyelink.use && Eyelink('IsConnected')
    % edfFile = fullfile(dv.el.edfFileLocation, dv.el.edfFile);
    edfFile = dv.defaultParameters.eyelink.edfFile;
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    % download data file
    if dv.defaultParameters.eyelink.saveEDF
        try
            fprintf('Receiving data file ''%s''\n', edfFile);
            %     status=Eyelink('ReceiveFile', dv.el.edfFile, dv.el.edfFileLocation);
            status=Eyelink('ReceiveFile', edfFile);
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if 2==exist(edfFile, 'file')
                fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile);
            end
            dv.defaultParameters.eyelink.edfData = mglEyelinkEDFRead(edfFile, 1);

        catch rdf
            fprintf('Problem receiving data file ''%s''\n', edfFile );
        end
    end
    Eyelink('Shutdown')
end

