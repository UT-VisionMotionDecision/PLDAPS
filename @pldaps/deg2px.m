% convert from deg to pixel coordinates
%---------------------------------------------------------------------%
function [xy,z] = deg2px(p,xy,z,zIsR)
    if(nargin<3)
        z=p.trial.display.viewdist;
    end
    
    xy=sind(xy);
    
    if(nargin>3 && zIsR) %z argument is the radius/total distance
        sr=sqrt(z);
    else
        sr=z./sqrt(1-sum(xy.^2));
    end
    
    xy=[p.trial.display.w2px(1)*sr; p.trial.display.w2px(2)*sr].*xy;
    
    if(nargout>1 && nargin<4 && zIsR)
        z=mean(p.trial.display.w2px)*sr.*sqrt(1-sum(xy.^2));
    end
    
end