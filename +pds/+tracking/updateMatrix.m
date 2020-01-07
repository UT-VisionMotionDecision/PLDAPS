function matrixOutput = updateMatrix(p)
% function pds.tracking.updateMatrixGains(p)
% 
% Update calibration matrix based on parametric adjustments in .tracking.adjust


% [gainX, gainY, offsetX, offsetY, theta] = pds.tracking.matrix2Components(p.static.tracking.calib.matrix);

nSrc = numel(p.trial.tracking.srcIdx);


for i = 1:nSrc
    s = p.static.tracking.adjust.val(i);
    % skip if no adjustments
    if any(struct2array(s))
        [gainX, gainY, offsetX, offsetY, theta] = pds.tracking.matrix2Components(p.static.tracking.calib.matrix(i));
        s.gainX   = gainX + s.gainX;
        s.gainY   = gainY + s.gainY;
        s.offsetX = offsetX + s.offsetX;
        s.offsetY = offsetY + s.offsetY;
        s.theta   = theta + s.theta;
        
%         sinTh = sind(s.theta);
%         cosTh = cosd(s.theta);
        
        %     R = [cosTh -sinTh; sinTh cosTh; 0 0] .* [s.gainX s.gainX; s.gainY s.gainY; 0 0];
        %     S = [0 0; 0 0; s.offsetX s.offsetY];
        %     C = R + S;
        
        % Compile components
        [T, R, S] = deal(eye(3));
        % rotate
        R = rotz(s.theta);
        % translate
        T(3,1) = s.offsetX;
        T(3,2) = s.offsetY;
        % scale
        S(1,1) = s.gainX;
        S(2,2) = s.gainY;
        
        % Combined calibration matrix
        p.static.tracking.calib.matrix(i).T = R * T * S;
        fprintf('~~\tadjusted tracking calibration matrix\n')
        % NOTE: R*T*S order important for component extraction with pds.tracking.matrix2Components.m
    end
%     s.R = R;
%     s.T = T;
%     s.S = S;
%     s.C = C;
%     
%     p.trial.tracking.adjust.val(i) = s;
%     p.trial.tracking.calib.matrix(i) = C;
    
end

% clear adjustment params
p.static.tracking.adjust.val(1:nSrc) = struct('gainX',0, 'gainY',0, 'offsetX',0, 'offsetY',0, 'theta',0);

% Update active calibration matrix
p.trial.tracking.calib.matrix = cat(3, p.static.tracking.calib.matrix.T);

if nargout==0
    return
else
    matrixOutput = p.static.tracking.calib.matrix;%p.trial.tracking.calib.matrix;
end