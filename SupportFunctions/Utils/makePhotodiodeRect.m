function dv = makePhotodiodeRect(dv)
% rect = makePhotodiodeRect(dv, location)
% makePhotodiodeRect makes a 4 coordinate rectangle for PTB fillRect calls
% INPUTS
%   dv [struct]
%     .trial
%       .pldaps             %pldaps internal parameters
%         .draw
%           .photodiode
%             .use
%             .location
%       .diaplay
%           .ppd     [1x1] pixels per degree
%           .winRect [1x4] screen coords [x_ul, y_ul, x_br, y_br]
% OUTPUT
% dv [struct]
%     .trial
%       .pldaps             %pldaps internal parameters
%         .draw
%           .photodiode
%             .rect

% 12/15/2013 jly    Wrote it
% 06/03/2014 jk     made compatible with pldaps class

if(dv.defaultParameters.pldaps.draw.photodiode.use)
    switch dv.defaultParameters.pldaps.draw.photodiode.location
        case 1
            rect = [dv.defaultParameters.display.winRect(1:2) dv.defaultParameters.display.winRect(1:2)+dv.defaultParameters.display.ppd];
        case 2
            rect = [dv.defaultParameters.display.winRect(1) dv.defaultParameters.display.winRect(4)-dv.defaultParameters.display.ppd ...
                dv.defaultParameters.display.winRect(1)+dv.defaultParameters.display.ppd dv.defaultParameters.display.winRect(4)];
        case 3
            rect = [dv.defaultParameters.display.winRect(3)-dv.defaultParameters.display.ppd dv.defaultParameters.display.winRect(2)...
                dv.defaultParameters.display.winRect(3) dv.defaultParameters.display.winRect(2)+dv.defaultParameters.display.ppd];
        case 4
            rect = [dv.defaultParameters.display.winRect(3:4)-dv.defaultParameters.display.ppd dv.defaultParameters.display.winRect(3:4)];
        otherwise
            rect = [dv.defaultParameters.display.winRect(1) dv.defaultParameters.display.winRect(4)-dv.defaultParameters.display.ppd ...
                dv.defaultParameters.display.winRect(1)+dv.defaultParameters.display.ppd dv.defaultParameters.display.winRect(4)];
    end
    
    dv.trial.pldaps.draw.photodiode.rect=rect;
end