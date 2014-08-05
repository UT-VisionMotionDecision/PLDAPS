% convert from deg to world coordinates
%---------------------------------------------------------------------%
function [xy,z] = deg2world(p,xy,z,zIsR)

    if(nargin<3)
        z=p.trial.display.viewdist;
    end
    
    xy=sind(xy);
    
    if(nargin>3 && zIsR) %z argument is the radius/total distance
        sr=sqrt(z);
    else
        sr=z./sqrt(1-sum(xy.^2));
    end
    
    xy=[sr; sr].*xy;
    
    if(nargout>1 && nargin<4 && zIsR)
        z=sr.*sqrt(1-sum(xy.^2));
    end

%this code was wrong!
% 	xy=tand(xy).*dv.trial.display.viewdist.*secd(flipud(xy));
        
        %this code is a little slower
%         xy=tand(xy);
%         xy=xy*dv.trial.display.viewdist.*sqrt(1+flipud(xy).^2);

end