function [xy,z] = world2deg(xy,z)
%world2deg    convert from world coordinates to degrees of visual angle
% calculates the degrees of visual angle for an array of world coordinates
% taking the depence of x and y degrees into account (i.e. that the
% distance of the position e.g. y increases when x is large
%
% [xy,z] = world2deg(xy,z)
% xy is a [2 x N] array of x and y world coordinates
% z (optional) is the viewing distance, which is assumed to be the orthogonal
%               distance of the observer to the screen and  defaults to 
%               p.trial.display.viewdist if not provided.
% the result is
% xy, a [2 x N] array of world coordinates and the optical output
% z, [1 x N] vector of distances to those locations
   
    %% caculate radius to tmp variable if requested
    if(nargout>1) %radius output requested
        r=sum(xy.^2 + 0.5*z.^2);      %calculate radius/distance from viewer
    end
    
    %% do the actual conversion
    if(size(z,2)~=1)
        xy=atand(xy./sqrt(flipud(xy).^2+[z;z].^2));
    else
        xy=atand(xy./sqrt(flipud(xy).^2+z.^2));
    end
     
    %%copy over z
    if(nargout>1) %radius output requested
        z=r;
    end
end