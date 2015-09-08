function xy = world2deg2(xyz, z)
%world2deg    convert from world coordinates to degrees of visual angle
% calculates the degrees of visual angle for an array of world coordinates
% taking the depence of x and y degrees into account (i.e. that the
% distance of the position e.g. y increases when x is large
%
% [xy] = world2deg(xyz,z)
% p is a pldaps class or a struct with the field p.trial.display.viewdist
                % p.trial.display.px2w
% xyz is a [2 x N] or [3 x N] array of x and y (and z) world coordinates 
% z (optional) is the viewing distance, which is assumed to be the orthogonal
%               distance of the observer to the screen.
% the result is
% xy, a [2 x N] array of world coordinates and the optical output
    if nargin > 1
        xy=atand(xyz(1:2,:)./sqrt(flipud(xyz(1:2,:)).^2+z.^2));
    else
        z=xyz(3,:);
        xy=atand(xyz(1:2,:)./sqrt(flipud(xyz(1:2,:)).^2+[z;z].^2));
    end
end

