function result = saveTempFile(p)
%saveTempFile    save the data from a single Trial to a file in a TEMP
%                folder
% result = saveTempFile(p)
result= [];
if ~p.trial.pldaps.nosave && p.trial.pldaps.save.trialTempfiles
	evalc(['trial' num2str(p.trial.pldaps.iTrial) '= p.trial']);
    if ~exist([p.trial.session.dir filesep 'TEMP'],'dir')
        warning('pldaps:saveTempFile','TEMP directory in data directory does not exist, trying to create it')
        try
            mkdir(fullfile(p.trial.session.dir,'TEMP'));
        catch result
            warning('pldaps:saveTempFile','Failed creating TEMP directory in %s',p.trial.session.dir)
            p.trial.pldaps.quit = 2;
            return;
        end
    end
    try  
        save(fullfile(p.trial.session.dir,'TEMP',[p.trial.session.file(1:end-4) num2str(p.trial.pldaps.iTrial) p.trial.session.file(end-3:end)]),['trial' num2str(p.trial.pldaps.iTrial)]);
    catch result
         warning('pldaps:saveTempFile','Failed to save temp file in %s',[p.trial.session.dir filesep 'TEMP'])
    end
end