function result = pdsSaveTempFile(dv,PDS)
% result = pdsSaveTempFile(dv,PDS)
% save data for each trial in TEMP file

result = [];

% extract end of PDS -- takes less than 1ms
PDStemp = structfun(@(x) ( x(end) ), PDS, 'UniformOutput', false);
% if data and timing variables are stored (extract end of those
% too) -- takes less than 1 ms
% Sorry - this next part is hacky. Switch to if-else statements
% instead of try catch - jly
try
    PDStemp.timing = structfun(@(x) ( x(end) ), PDS.timing, 'UniformOutput', false);
catch result
end
try
    PDStemp.data   = structfun(@(x) ( x(end) ), PDS.data, 'UniformOutput', false);
catch result
end
% save -- takes 40 ms
if ~isfield(dv, 'nosave')
    try
        save(fullfile(dv.pref.datadir,'TEMP',[dv.pref.sfile num2str(dv.j)]),'PDStemp','dv');
    catch result
        mkdir(fullfile(dv.pref.datadir,'TEMP'));
        save(fullfile(dv.pref.datadir,'TEMP',[dv.pref.sfile num2str(dv.j)]),'PDStemp','dv');
    end
end