function fdat = pdsGetModuleField(d, field, modNames)
%
% Retrieve data of one particular [field] from each of the modules that were presented.
%   -"were presented" being key...must be flagged as .shown = 1;
% 
% [modNames] can be retrieved from the pds "baseParams" portion of the main structure.
%       (i.e. this list will not be in each pds.data{n}, and must be passed as input)
% 
%       modNames = pds.baseParams.pldaps.modNames.matrixModule;

% modNames = [{'dotBall01'}    {'dotBall02'}    {'dotBall03'}    {'dotBall04'}    {'dotBall05'}    {'dotBall06'}];
% field = 'dotSpdCm';

% get list of module names present in this trial
fn = fieldnames(d);
fn = fn(ismember(fn,modNames));

fdat = [];
c = 1;
for i = 1:length(fn)
    if (isfield(d.(fn{i}), 'shown') && d.(fn{i}).shown)
        if isfield(d.(fn{i}), field)
            fdat(:,c) = d.(fn{i}).(field)(:);
            c = c+1;
        end
    end
end

end %main function