function p = fetchEdf(inDir)
%pds.eyelink.fetchEdf_dir
% Retrieve EDF files corresponding to all PDS files found in [inDir]
%   [inDir] can be string path, or cell of paths
%   --if no inputs provided, will work from current directory
% 
% 2019-04-12  TBC  Wrote it.


% Parse inputs
if nargin < 1 || isempty(inDir)
    inDir = {pwd};
end
if ~iscell(inDir)
    inDir = {inDir};
end

%% Connect to Eyelink
if ~Eyelink('IsConnected')
    Eyelink('Initialize');
end

% Do we need to preemptively stop & close recording? 
% This is a cleanup/post-hoc function, so sholdn't be in active use
% when calling this fxn in first place.
%     Eyelink('StopRecording');
%     Eyelink('CloseFile');


%% For each dir...
for d = 1:length(inDir)
    thisPath = inDir{d};
    
    %% Find PDS files
    theseFiles = dir( fullfile(thisPath,'*.PDS'));
    if isempty(theseFiles)
        % check ./pds subfolder (default location for day's session
        thisPath = fullfile(thisPath,'pds');
        theseFiles = dir( fullfile(thisPath,'*.PDS'));
        % None found
        if isempty(theseFiles)
            warning('No PDS files found in dir:\n\t%s\n',thisPath);
            continue
        end
    end
    
    
    nFiles = length(theseFiles);
    fprintLineBreak;
    fprintf('Fetching EDF files for %d PDS files in %s:\n', nFiles, thisPath);
    fprintLineBreak;
    
    %% Process EDF file for each PDS
    for i = 1:length(theseFiles)
        thisFile = fullfile(theseFiles(i).folder, theseFiles(i).name);
        baseParams = [];
        % Load the baseParams field only (we don't need the rest)
        load(thisFile,'-mat', 'baseParams')
        
        %% Transfer EDF file
        tic;

        % Determine destination for EDF file
        %         % --First check if there is an "eye" dir one up from the dir enclosing this PDS
        %         %   --if so, put EDF there (like normal .saveEDF would
        %         edfDestPath = fullfile(theseFiles(i).folder, '..','eye');
        %         if ~exist(edfDestPath, 'dir')
        %         %   --else, save EDF to same dir as PDS
        %             edfDestPath = fullfile(theseFiles(i).folder);
        %         end
        
        % Construct file name
        edfFile = baseParams.eyelink.edfFile;
        file = baseParams.session.file;
        dirs = baseParams.session.dir;
        filename = fullfile( dirs, 'eye', [file(1:end-3) 'edf']);
        
        % Get data from Eyelink
        fprintf('%d of %d:\t', i, nFiles);
        
        if exist(filename,'file')
            fprintf('\tEDF file already exists for %s\n\t...moving on.\n', filename)
        else
            % Begin file transfer
            try
                fprintf('Receiving Eyelink data...');
                err = Eyelink('Receivefile', edfFile, filename);
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
        
    end
    
    if isempty(baseParams)
        % didn't actually find any...we already reported that, but tell user none were processed
        % since it could be a loading problem(?)
        keyboard
    else
        % Tell user all PDS files in [thisPath] have been processed
        fprintf('\n~~~\tTransfer of all PDS files in %s complete.\n\n', thisPath)
    end
    
end
% Close Eyelink connection
Eyelink('Shutdown')

% Tell user we're all done
fprintLineBreak
fprintf('EDF file transfers complete.\n')
fprintLineBreak

end %main function
