% convert from deg to world coordinates
%---------------------------------------------------------------------%
function [xy] = deg2world(dv,xy)
	xy=tand(xy).*dv.trial.display.viewdist.*secd(flipud(xy));
        
        %this code is a little slower
%         xy=tand(xy);
%         xy=xy*dv.trial.display.viewdist.*sqrt(1+flipud(xy).^2);

end