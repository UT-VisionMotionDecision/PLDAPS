function rect = makePhotodiodeRect(dv, location)
% rect = makePhotodiodeRect(dv, location)
% makePhotodiodeRect makes a 4 coordinate rectangle for PTB fillRect calls
% INPUTS
%   dv [struct]
%       .disp
%           .ppd     [1x1] pixels per degree
%           .winRect [1x4] screen coords [x_ul, y_ul, x_br, y_br]

% 12/15/2013 jly    Wrote it

switch location
    case 1
        rect = [dv.disp.winRect(1:2) dv.disp.winRect(1:2)+dv.disp.ppd];
    case 2
        rect = [dv.disp.winRect(1) dv.disp.winRect(4)-dv.disp.ppd ...
            dv.disp.winRect(1)+dv.disp.ppd dv.disp.winRect(4)];
    case 3
        rect = [dv.disp.winRect(3)-dv.disp.ppd dv.disp.winRect(2)...
            dv.disp.winRect(3) dv.disp.winRect(2)+dv.disp.ppd];
    case 4
        rect = [dv.disp.winRect(3:4)-dv.disp.ppd dv.disp.winRect(3:4)];
    otherwise
        rect = [dv.disp.winRect(1) dv.disp.winRect(4)-dv.disp.ppd ...
            dv.disp.winRect(1)+dv.disp.ppd dv.disp.winRect(4)];
end