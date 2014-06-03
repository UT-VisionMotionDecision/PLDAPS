% convert from pixel to deg coordinates
%---------------------------------------------------------------------%
function [xy] = px2deg(dv,xy)
%         xy=diag(dv.trial.display.px2w)*xy;
%         xy=atand(xy/dv.trial.display.viewdist);
        xy=diag(dv.trial.display.px2w)*xy;
        xy=atand(xy./sqrt(flipud(xy).^2+dv.trial.display.viewdist.^2));
end