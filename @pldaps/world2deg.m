% convert from world to deg coordinates
%---------------------------------------------------------------------%
function [xy,z] = world2deg(dv,xy,z)
%         xy=atand(xy/dv.trial.display.viewdist);
    if(nargin<3)
        z=dv.trial.display.viewdist;
    end
   
    %% caculate radius to tmp variable if requested
    if(nargout>1) %radius output requested
        r=sum(xy.^2 + 0.5*z.^2);      %calculate radius/distance from viewer
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