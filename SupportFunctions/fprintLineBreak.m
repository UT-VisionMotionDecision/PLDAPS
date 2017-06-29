function fprintLineBreak(txt, n)
% function fprintLineBreak(txt, n)
% 
% Print a standardized line of text[txt] to the command window [n] times,
%   defaults:  tex='*';  n=65;
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
    n = 65;
end

fprintf( [repmat(txt ,[1,n]), '\n']);