function dv = pdsGitSetup(dv)
%
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

dv.defaultParameters.git.pldaps.status = git(['- c ' pldapspath ' status']);
dv.defaultParameters.git.pldaps.diff = git(['- c ' pldapspath ' diff']);
dv.defaultParameters.git.pldaps.revision =git(['-C'  pldapspath ' rev-parse HEAD']);

huklabpath=which('defaultTrialVariables');
huklabpath=huklabpath(1:end-length('/defaultTrialVariables.m'));

dv.defaultParameters.git.huklabBasics.status = git(['- c ' huklabpath ' status']);
dv.defaultParameters.git.huklabBasics.diff = git(['- c ' huklabpath ' diff']);
dv.defaultParameters.git.huklabBasics.revision =git(['-C'  huklabpath ' rev-parse HEAD']);