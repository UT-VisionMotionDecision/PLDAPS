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
    
        %this code ignored the dependence of the two angles!
% xy=(diag(dv.trial.display.w2px).*dv.trial.display.viewdist)*tand(xy);
%         xy(1,:)=dv.trial.display.w2px(1) *dv.trial.display.viewdist*tand(xy(1,:));
%         xy(2,:)=dv.trial.display.w2px(2) *dv.trial.display.viewdist*tand(xy(2,:));
end