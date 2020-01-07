function [gainX, gainY, offsetX, offsetY, theta] = matrix2Gains(C)
% [gainX, gainY, offsetX, offsetY, theta] = calibrationMatrixToGains(C)
% Convert a calibration matrix to gains and offsets

[thx, rhoX] = cart2pol(C(1,1), C(1,2));
[thy, rhoY] = cart2pol(C(2,1), C(2,2));

delta = angle(exp(1i*(thx - thy)));
if (delta - pi) < 1e-3
    rhoY = -rhoY;
else
    assert( delta < 1e-3)
end

offsetX = C(3,1);
offsetY = C(3,2);
gainX   = rhoX;
gainY   = rhoY;
theta   = thx/pi*180;