% convert from deg to pixel coordinates
%---------------------------------------------------------------------%
function xy = deg2px(dv,xy)
    xy=diag(dv.trial.display.w2px)*tand(xy)*dv.trial.display.viewdist.*secd(flipud(xy));    
%this code is a little slower
%         xy=tand(xy);
%         xy=diag(dv.trial.display.w2px).xy*dv.trial.display.viewdist.*sqrt(1+flipud(xy).^2);    
       
        
        %this code ignored the dependence of the two angles!
% xy=(diag(dv.trial.display.w2px).*dv.trial.display.viewdist)*tand(xy);
%         xy(1,:)=dv.trial.display.w2px(1) *dv.trial.display.viewdist*tand(xy(1,:));
%         xy(2,:)=dv.trial.display.w2px(2) *dv.trial.display.viewdist*tand(xy(2,:));
end