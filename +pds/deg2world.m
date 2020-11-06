function [xy, z] = deg2world(xyIn, z, zIsR)
%deg2world    convert from degrees of visual angle to world coordinates
% calculates the world coordinates for an array of degress of visul angle
% taking the depence of x and y degrees into account (i.e. that the
% distance of the position e.g. y increases when x is large
%
% [xy,z] = deg2world(xy,z,zIsR)
% xy is a [2 x N] array of x and y degress of visual angle
% z (optional) is the viewing distance, which is assumed to be the orthogonal
%               distance of the observer to the screen unless
% zIsR is specified in which case, z is treated as the distance of the
%               observer to the location.
% 
% the result is
% xy, a [2 x N] array of world coordinates and the optional output
% z, [1 x N] vector of distances to those locations
%
% using [xy,z] = pds.deg2world(xy, p.trial.display.viewdist, true) would calculate
% the world coordinates for indipendent angles, i.e. where the results of x
% is indepent of y. This is not correct, but may be ok, for small screens
% or mainly cardinal coordinates.

    if nargin<3 || isempty(zIsR)
        zIsR = false;
    end
    % check proper xy input orientation
    if numel(xyIn)==2
        xyIn = xyIn(:);
    elseif size(xyIn,2)==2 && size(xyIn,1)~=2
        xyIn = xyIn';
    end
    
    xy = sind(xyIn);
    
    if zIsR %z argument is the radius/total distance
        if isscalar(z)
            z = z * ones(1,size(xy,2));
        end
        sr = z;
    else
        sr = z./sqrt(1-sum(xy.^2));
    end
    
    xy = sr.*xy;

    if nargout>1 && ~zIsR 
        z =  z./sqrt(1-sum(sind(xyIn).^2)); %sr.*sqrt(1-sum(xyIn.^2));
    end
end