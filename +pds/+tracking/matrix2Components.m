function [gainX, gainY, offsetX, offsetY, theta] = matrix2Components(tform)
% [gainX, gainY, offsetX, offsetY, theta] = calibrationMatrixToGains(C)
% Convert a calibration matrix to gains offsets & rotations
% 
% [tform] input can be transform object or 3x3xN matrix
% 
% 2019-07-29  TBC  Wrote it.


if isa(tform, 'images.geotrans.internal.GeometricTransformation')
    C = cat(3, tform.T);
end

for i = 1:size(C,3)
    
    
    [thx, rhoX] = cart2pol(C(1,1), C(1,2));
    [thy, rhoY] = cart2pol(C(2,1), C(2,2));
    
    % why would you want/need this flip?
    % %     delta = angle(exp(1i*(thx - thy)));
    % %     if (delta - pi) < 1e-3
    % %         rhoY = -rhoY;
    % %     else
    % %         assert( delta < 1e-3)
    % %     end
    
    offsetX(i) = C(3,1);
    offsetY(i) = C(3,2);
    gainX(i)   = rhoX;
    gainY(i)   = rhoY;
    theta(i)   = thx/pi*180;
end


end %main function

