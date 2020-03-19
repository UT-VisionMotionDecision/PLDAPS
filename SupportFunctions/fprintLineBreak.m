function output = fprintLineBreak(txt, n)
% function [output] = fprintLineBreak(txt, n)
% 
% --If no output assigned in caller:
%   Print a standardized line of text[txt] to the command window [n] times,
%   defaults:  tex='*';  n=65;
% 
% --If output assigned in caller:
%   Return string instead of printing to command window
% 
%   fprintf( [repmat(txt ,[1,n]), '\n']);
% 
% 2017-06-27  tbc  Wrote it.
% 


% what char/str to repeat
if nargin<1 || isempty(txt)
    txt = '*';
end
% how many repeats
if nargin<2 || isempty(n)
    n = 64;     % standard length
elseif ~isinteger(n)
    n = round(64*n);   % allow scaling of standard length
end

if nargout<1
    fprintf( [repmat(txt ,[1,n]), '\n']);
    return;%
else
    output = sprintf( [repmat(txt ,[1,n]), '\n']);
end