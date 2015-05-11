function [xy,z] = deg2world(p,xy,z,zIsR)
%deg2world    convert from degrees of visual angle to world coordinates
% calculates the world coordinates for an array of degress of visul angle
% taking the depence of x and y degrees into account (i.e. that the
% distance of the position e.g. y increases when x is large
%
% [xy,z] = deg2world(p,xy,z,zIsR)
% p is a pldaps class or a struct with the field p.trial.display.viewdist p.trial.display.w2px
% xy is a [2 x N] array of x and y degress of visual angle
% z (optional) is the viewing distance, which is assumed to be the orthogonal
%               distance of the observer to the screen unless
% zIsR is specified in which case, z is treated as the distance of the
%               observer to the location.
% z defaults to p.trial.display.viewdist if not provided.
% the result is
% xy, a [2 x N] array of world coordinates and the optional output
% z, [1 x N] vector of distances to those locations
%
% using [xy,z] = deg2world(p,xy,p.trial.display.viewdist,true) would calculate
% the world coordinates for indipendent angles, i.e. where the results of x
% is indepent of y. This is not correct, but may be ok, for small screens
% or mainly cardinal coordinates.

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
end