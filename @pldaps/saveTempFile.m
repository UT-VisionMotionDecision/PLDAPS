function result = saveTempFile(p)
%saveTempFile    save the data from a single Trial to a file in a TEMP
%                folder
% result = saveTempFile(p)
if ~p.defaultParameters.pldaps.nosave
    evalc(['trial' num2str(p.trial.pldaps.iTrial) '= p.trial']);

    try  
        result=[];
        save(fullfile(p.trial.session.dir,'TEMP',[p.trial.session.file(1:end-4) num2str(p.trial.pldaps.iTrial) p.trial.session.file(end-3:end)]),['trial' num2str(p.trial.pldaps.iTrial)]);
    catch result
        mkdir(fullfile(p.trial.session.dir,'TEMP'));
        save(fullfile(p.trial.session.dir,'TEMP',[p.trial.session.file(1:end-4) num2str(p.trial.pldaps.iTrial) p.trial.session.file(end-3:end)]),['trial' num2str(p.trial.pldaps.iTrial)]);
    end
end