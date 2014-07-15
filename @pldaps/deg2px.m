% convert from deg to pixel coordinates
%---------------------------------------------------------------------%
function [xy,z] = deg2px(dv,xy,z,zIsR)

    if(nargin<3)
        z=dv.trial.display.viewdist;
    end
    
    sinxy=sind(xy);
    
    if(nargin>3 && zIsR) %z argument is the radius/total distance
        sr=sqrt(z);
    else
        sr=z./sqrt(1-sum(sinxy.^2));
    end
    
    xy=diag(dv.trial.display.w2px)*[sr; sr].*sinxy;
    
    if(nargout>1 && nargin<4 && zIsR)
        z=mean(dv.trial.display.w2px)*sr.*sqrt(1-sum(sinxy.^2));
    end
    
%this code is wrong
%     xy=diag(dv.trial.display.w2px)*tand(xy)*dv.trial.display.viewdist.*secd(flipud(xy));    
%this code is a little slower
%         xy=tand(xy);
%         xy=diag(dv.trial.display.w2px).xy*dv.trial.display.viewdist.*sqrt(1+flipud(xy).^2);    
       
        
        %this code ignored the dependence of the two angles!
% xy=(diag(dv.trial.display.w2px).*dv.trial.display.viewdist)*tand(xy);
%         xy(1,:)=dv.trial.display.w2px(1) *dv.trial.display.viewdist*tand(xy(1,:));
%         xy(2,:)=dv.trial.display.w2px(2) *dv.trial.display.viewdist*tand(xy(2,:));
end