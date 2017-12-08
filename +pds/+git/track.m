function p = track(p, fname)
% tack git repo for specified file
% p = pds.git.track(p, fname)
% Input:
%   p@pldaps   - a pldaps
%   fname@char - string to the file to be tracked
% Output:
%   p@pldaps

% 12/2017 jly	wrote it

fpath = which(fname);

[fpath, fname, ~] = fileparts(fpath);

p.defaultParameters.git.(fname).status = pds.git.git(['-C ' fpath ' status']);
p.defaultParameters.git.(fname).diff = pds.git.git(['-C ' fpath ' diff']);
p.defaultParameters.git.(fname).revision = pds.git.git(['-C '  fpath ' rev-parse HEAD']);