function out = circlewindow(pass,a,rx,ry)
% CIRCLEWINDOW is a boolean that is true if cartesian coordinates a (x,y) 
% are within an ellipse given by RX (x radius) and RY (y radius).  "a" must
% be specified from the center of the window. 
%
% RY is optional.  Defining only RX will result in circle window
% 
% If PASS is on, it always returns TRUE. 
%
% KLB 5/2013
%
if nargin < 4
    ry = rx; 
end

if pass == 0 
    out =  (a(1)^2)/(rx^2) + (a(2)^2)/(ry^2) <= 1;
else 
    out = 1;
end

