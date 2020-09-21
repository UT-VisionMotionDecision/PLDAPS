function result = saveTempFile(p, saveAll)
%function result = saveTempFile(p, saveAll)
% save the data from a single Trial to a .TEMP file
% Only saves contents of p.trial to temp file by default,
% set optional input [saveAll] to save the entire PLDAPS object
% instead of only p.trial
% 
% TEMP file location ==  fullfile(p.trial.pldaps.dirs.data, '.TEMP')
% 
% 201x-xx-xx --- Written as a pldaps component
% 2020-09-10 TBC Added saveAll option
% 

if nargin<2
    saveAll = false;
end

result= [];

trialString = sprintf('trial%05d', p.trial.pldaps.iTrial);
[~, fname, fext] = fileparts(p.trial.session.file);
tmpDir = fullfile(p.trial.pldaps.dirs.data, '.TEMP');
tmpFile = fullfile(tmpDir, [fname, trialString, fext]);

if ~p.trial.pldaps.nosave && p.trial.pldaps.save.trialTempfiles
    % make separate copy of p.trial (...why??)
	evalc( sprintf('%s = p.trial', trialString) );
    
    if ~exist(tmpDir,'dir')
        warning('pldaps:saveTempFile','TEMP directory in data directory does not exist, trying to create it')
        try
            mkdir(tmpDir);
        catch result
            warning('pldaps:saveTempFile','Failed creating TEMP directory:\t%s', tmpDir)
            p.trial.pldaps.quit = 2;
            return;
        end
    end
    try 
        if ~saveAll
            save( tmpFile, trialString);
        else
            % save complete PLDAPS session object (not just p.trial contents)
            save( tmpFile, '-mat', 'p');
        end
        
    catch result
         warning('pldaps:saveTempFile','Failed to save temp file in %s', tmpDir)
    end
end
