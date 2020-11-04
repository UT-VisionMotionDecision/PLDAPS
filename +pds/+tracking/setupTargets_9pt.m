%% setupTargets(p)
function targets = setupTargets_9pt(p)
%function targets = pds.tracking.setupTargets_9pt(p)
% 
% Create tracking calibration target positions struct
targets = struct();

halfWidth_x = p.trial.tracking.gridSz(1)/2;
halfWidth_y = p.trial.tracking.gridSz(end)/2;

% basic 9-point target grid (in degrees)
xx = -halfWidth_x:halfWidth_x:halfWidth_x;
yy = -halfWidth_y:halfWidth_y:halfWidth_y;
[xx, yy] = meshgrid(xx, yy);
% arrange to match numpad
xy = sortrows([xx(:),yy(:)], [-2,1]);
if 1
    % add inner target points
    [x2, y2] = meshgrid( halfWidth_x/2*[-1 1], halfWidth_y/2*[1 -1]);
    xy = [xy; [x2(:), y2(:)]];
end
zz = zeros(size(xy,1),1);

targets.targPos = [xy, zz(:)]' ;
% Target position in WORLD coordinates [CM]
% add targPos to the viewDist baseline for final depth in world coordinates
targets.targPos(3,:) = targets.targPos(3,:) + p.trial.display.viewdist;
% % Ideally draw in 3D:
%   % convert XY degrees to CM, given the distance in depth CM
%   targets.targPos(1:2,:) = pds.deg2world(targets.targPos(1:2,:)', targets.targPos(3,:), 0); % p.deg2world(p, p.trial.(sn).stimPosDeg(1:2)');      %
% % ...use Pixels in a pinch
targets.xyPx = pds.deg2px(targets.targPos(1:2,:), targets.targPos(3,:), p.trial.display.w2px,  0) + p.trial.display.ctr(1:2)';

targets.timeUpdated = GetSecs;
targets.nTargets = size(targets.targPos,2);
targets.randOrd = randperm(targets.nTargets);


end

