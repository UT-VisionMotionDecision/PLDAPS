function result = saveTempFile(dv)
% result = pdsSaveTempFile(dv,PDS)
% save data for each trial in TEMP file

% result = [];
% 
% % extract end of PDS -- takes less than 1ms
% PDStemp = structfun(@(x) ( x(end) ), PDS, 'UniformOutput', false);
% % if data and timing variables are stored (extract end of those
% % too) -- takes less than 1 ms
% % Sorry - this next part is hacky. Switch to if-else statements
% % instead of try catch - jly
% try
%     PDStemp.timing = structfun(@(x) ( x(end) ), PDS.timing, 'UniformOutput', false);
% catch result
% end
% try
%     PDStemp.data   = structfun(@(x) ( x(end) ), PDS.data, 'UniformOutput', false);
% catch result
% end
% save -- takes 40 ms
if ~dv.defaultParameters.pldaps.nosave
    evalc(['trial' num2str(dv.trial.pldaps.iTrial) '= dv.trial']);

    try  
        result=[];
        save(fullfile(dv.trial.session.dir,'TEMP',[dv.trial.session.file(1:end-4) num2str(dv.trial.pldaps.iTrial) dv.trial.session.file(end-3:end)]),['trial' num2str(dv.trial.pldaps.iTrial)]);
    catch result
        mkdir(fullfile(dv.trial.session.dir,'TEMP'));
        save(fullfile(dv.trial.session.dir,'TEMP',[dv.trial.session.file(1:end-4) num2str(dv.trial.pldaps.iTrial) dv.trial.session.file(end-3:end)]),['trial' num2str(dv.trial.pldaps.iTrial)]);
    end
end