function p = setup(p)
%pds.git.setup   retrieves and stores git info about relevant directories
%
% gets and eylink time estimate and send a TRIALSTART message to eyelink
% sets up the git information about the used code.
% at the moment this hold all changes of the PLDAPS and huklabBasics repo
% should probably change to something more specific.
%
% p = pds.git.setup(p)
%
% 05/2014 jk wrote it

if ~isField(p.defaultParameters,'git.use') || ~p.defaultParameters.git.use
    return
end

pldapspath=which('pldaps');
pldapspath=pldapspath(1:end-length('/@pldaps/pldaps.m'));

p.defaultParameters.git.pldaps.status = pds.git.git(['-C ' pldapspath ' status']);
p.defaultParameters.git.pldaps.diff = pds.git.git(['-C ' pldapspath ' diff']);
p.defaultParameters.git.pldaps.revision =pds.git.git(['-C '  pldapspath ' rev-parse HEAD']);

huklabpath=which('defaultTrialVariables');
huklabpath=huklabpath(1:end-length('/defaultTrialVariables.m'));

p.defaultParameters.git.huklabBasics.status = pds.git.git(['-C ' huklabpath ' status']);
p.defaultParameters.git.huklabBasics.diff = pds.git.git(['-C ' huklabpath ' diff']);
p.defaultParameters.git.huklabBasics.revision =pds.git.git(['-C '  huklabpath ' rev-parse HEAD']);