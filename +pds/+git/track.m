function p = track(p, fname, gname)
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

if nargin < 3
    gname = fname;
    gname = strrep(gname, '.', '');
end

p.defaultParameters.git.(gname).status = pds.git.git(['-C ' fpath ' status']);
p.defaultParameters.git.(gname).diff = pds.git.git(['-C ' fpath ' diff']);
p.defaultParameters.git.(gname).revision = pds.git.git(['-C '  fpath ' rev-parse HEAD']);