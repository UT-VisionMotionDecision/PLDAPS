function dv = setup(dv)
% pds.git.setup
% sets up the git information about the used code.
% at the moment this hold all changes of the PLDAPS and huklabBasics repo
% should probably change to something more specific.
%
% 05/2014 jk wrote it

if ~isField(dv.defaultParameters,'git.use') || ~dv.defaultParameters.git.use
    return
end

pldapspath=which('pldaps');
pldapspath=pldapspath(1:end-length('/@pldaps/pldaps.m'));

dv.defaultParameters.git.pldaps.status = pds.git.git(['-C ' pldapspath ' status']);
dv.defaultParameters.git.pldaps.diff = pds.git.git(['-C ' pldapspath ' diff']);
dv.defaultParameters.git.pldaps.revision =pds.git.git(['-C '  pldapspath ' rev-parse HEAD']);

huklabpath=which('defaultTrialVariables');
huklabpath=huklabpath(1:end-length('/defaultTrialVariables.m'));

dv.defaultParameters.git.huklabBasics.status = pds.git.git(['-C ' huklabpath ' status']);
dv.defaultParameters.git.huklabBasics.diff = pds.git.git(['-C ' huklabpath ' diff']);
dv.defaultParameters.git.huklabBasics.revision =pds.git.git(['-C '  huklabpath ' rev-parse HEAD']);