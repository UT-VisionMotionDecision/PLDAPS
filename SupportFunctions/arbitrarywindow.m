function held = arbitrarywindow(pass, eyeXY, winXYXY)
%   held = arbitrarywindow(pass, eyeXY, winXYXY)
%
% the function is a boolian that returns 1 if pass==1, or if a given eye 
% position [x,y] is in the confounds of a given square window winXYXY of
% the form [xLeft yUp xRight yDown].
% all values should be in pixels.

if pass == 0 
    if (eyeXY(1) > winXYXY(1) && eyeXY(1) < winXYXY(3)) && ...
            (eyeXY(2) > winXYXY(2) && eyeXY(2) < winXYXY(4))
        held = 1;
    else
        held = 0;
    end
else 
    held = 1;
end

