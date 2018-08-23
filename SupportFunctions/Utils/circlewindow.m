function out = circlewindow(xy,rx,ry)
% CIRCLEWINDOW is a boolean that is true if cartesian coordinates xy (x,y) 
% are within an ellipse given by RX (x radius) and RY (y radius).  "xy" must
% be specified from the center of the window, sized n-by-2 (rows== observations,
% columns==[x,y]).
%
% RY is optional.  Defining only RX will result in circle window
% 
% REMOVED:  If PASS is on, it always returns TRUE. 
%
% KLB 5/2013
% TBC Removed pass input...if "pass" don't call this in first place
%
if numel(rx)>1
    ry = rx(2);
    rx = rx(1);
elseif nargin < 4
    ry = rx; 
end

out =  (xy(1,:).^2)/(rx^2) + (xy(2,:).^2)/(ry^2) <= 1;

