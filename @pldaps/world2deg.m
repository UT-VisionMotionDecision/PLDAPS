% convert from world to deg coordinates
%---------------------------------------------------------------------%
function [xy] = world2deg(dv,xy)
%         xy=atand(xy/dv.trial.display.viewdist);
          xy=atand(xy./sqrt(flipud(xy).^2+dv.trial.display.viewdist.^2));
end