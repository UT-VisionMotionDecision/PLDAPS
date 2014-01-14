function [opts] = pinputs(opts,vargs)
% [opts] = pinputs(opts,vargs)
% Process inputs and stick them into a structure
% takes in a struct and argument pairs and outputs a struct with variables
% that have the appropriate arguement
% INPUTS
%       opts - struct
%       varargin - argument pairs ('argument1', value1, 'arguement2', ...)
% OUTPUTS
%       opts - modified struct
%
% (c) jly 2012

if ~exist('opts', 'var') || isempty(opts)
    opts.subj        = 'jnk';
    opts.new_session = true;
    opts.rig         = 'rig2test092013';
    opts.condition   = [];
    opts.input       = [];
end

n    = length(vargs);
args = cell(n,1);
for ii = 1:n
    if ischar(vargs{ii})
        args{ii} = (vargs{ii});
    else
        args{ii} = vargs{ii};
    end
end

if (mod(n,2))
    error('Each option must be a string/value pair.');
end

for ind = 1:2:n
    opts.(lower(args{ind})) = args{ind+1};
end