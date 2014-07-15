% convert from pixel to deg coordinates
%---------------------------------------------------------------------%
function [xy,z] = px2deg(dv,xy,z)
%         xy=diag(dv.trial.display.px2w)*xy;
%         xy=atand(xy/dv.trial.display.viewdist);
    %% convert to world coords
    if(nargin>2) %got xyz, i.e. points in 3D world, not fixed to screen
        z=mean(dv.trial.display.px2w)*z;
    else
        z=dv.trial.display.viewdist;
    end
    xy=diag(dv.trial.display.px2w)*xy;

    %% caculate radius to tmp variable if requested
    if(nargout>1) %radius output requested
        r=sum(xy.^2 + z.^2);      %calculate radius/distance from viewer
    end
    
    %% do the actual conversion
    if(nargin>2 && size(z,2)~=1)
        xy=atand(xy./sqrt(flipud(xy).^2+[z;z].^2));
    else
        xy=atand(xy./sqrt(flipud(xy).^2+z.^2));
    end
     
    %%copy over z
    if(nargout>1) %radius output requested
        z=r;
    end
    
end