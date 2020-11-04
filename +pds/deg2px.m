function [xy,z] = deg2px(xyIn, z, w2px, zIsR)
% function [xy,z] = pds.deg2px(xyIn, z, w2px, zIsR)
% 
% convert from degrees of visual angle to pixel coordinates
% calculates the pixel coordinates for an array of degress of visul angle
% taking the depence of x and y degrees into account (i.e. that the
% distance of the position e.g. y increases when x is large
%
% [xy,z] = deg2px(xy,z,w2px,zIsR)
% xy is a [2 x N] array of x and y degress of visual angle
% z is the viewing distance, which is assumed to be the orthogonal
%               distance of the observer to the screen unless
% w2px is the conversion form world to px coordinates, i.e.
%               [numPixX/widthcm numPixY/heightcm]
% zIsR is specified in which case, z is treated as the distance of the
%               observer to the location.
% z defaults to p.trial.display.viewdist if not provided.
% the result is
% xy, a [2 x N] array of pixel coordinates and the optional output
% z, [1 x N] vector of distances to those locations
%
% using [xy,z] = deg2px(xy,p.trial.display.viewdist,p.trial.display.w2px,true) would calculate
% the pixel coordinates for independent angles, i.e. where the results of x
% is indepent of y. This is not correct, but may be ok, for small screens
% or mainly cardinal coordinates.

    if nargin<4 || isempty(zIsR)
        zIsR = false;
    end
    % check proper xy input orientation
    if numel(xyIn)==2
        xyIn = xyIn(:);
    elseif size(xyIn,2)==2 && size(xyIn,1)~=2
        xyIn = xyIn';
    end

    xy=sind(xyIn);
    
    if zIsR %z argument is the radius/total distance
        if isscalar(z)
            z = z * ones(1,size(xy,2));
        end
        sr=sqrt(z);
    else
        sr=z./sqrt(1-sum(xy.^2));
    end
    
    xy = w2px*sr.*xy;
    
    if nargout>1 && zIsR
        z=mean(w2px)*sr.*sqrt(1-sum(xy.^2));
    end
    
end