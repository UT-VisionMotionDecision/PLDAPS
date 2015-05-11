function [xy,z] = px2deg(p,xy,z)
%px2deg    convert from pixel coordinates to degrees of visual angle
% calculates the degrees of visual angle for an array of pixel coordinates
% taking the depence of x and y degrees into account (i.e. that the
% distance of the position e.g. y increases when x is large
%
% [xy,z] = px2deg(p,xy,z)
% p is a pldaps class or a struct with the field p.trial.display.viewdist
                % p.trial.display.px2w
% xy is a [2 x N] array of x and y pixel coordinates
% z (optional) is the viewing distance, which is assumed to be the orthogonal
%               distance of the observer to the screen and  defaults to 
%               p.trial.display.viewdist if not provided.
% the result is
% xy, a [2 x N] array of pixel coordinates and the optical output
% z, [1 x N] vector of distances to those locations
%

    %% convert to world coords
    if(nargin>2) %got xyz, i.e. points in 3D world, not fixed to screen
        z=mean(p.trial.display.px2w)*z;
    else
        z=p.trial.display.viewdist;
    end
    xy=diag(p.trial.display.px2w)*xy;

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