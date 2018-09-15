function result = saveTempFile(p)
%saveTempFile    save the data from a single Trial to a file in a TEMP
%                folder
% result = saveTempFile(p)

result= [];
tmpdir = fullfile(p.trial.pldaps.dirs.data, '.TEMP');
tmpfile = sprintf('trial%05d', p.trial.pldaps.iTrial);

if ~p.trial.pldaps.nosave && p.trial.pldaps.save.trialTempfiles
    % make separate copy of p.trial (...why??)
	evalc( sprintf('%s = p.trial', tmpfile) );
    
    if ~exist(tmpdir,'dir')
        warning('pldaps:saveTempFile','TEMP directory in data directory does not exist, trying to create it')
        try
            mkdir(tmpdir);
        catch result
            warning('pldaps:saveTempFile','Failed creating TEMP directory:\t%s', tmpdir)
            p.trial.pldaps.quit = 2;
            return;
        end
    end
    try  
        save( fullfile(tmpdir, [p.trial.session.file(1:end-4), tmpfile, p.trial.session.file(end-3:end)]), tmpfile);
    catch result
         warning('pldaps:saveTempFile','Failed to save temp file in %s', tmpdir)
    end
end