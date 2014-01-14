function out = squarewindow(pass,a,w,h)
% SQUAREWINDOW is a boolean that is true if 1 coordinates a(x,y) within a 
% square window given by W (width) and H (height). "a" is specified from
% the center of the window. 
% 
% If PASS is on, it always returns TRUE. 
if pass == 0 
    out = abs(a(1)) < w & abs(a(2)) < h;
else 
    out = 1;
end

