function [x,y] = datapixxGetEyePosition(dv)
%
% [x,y,unsmoothedline,v] = DatapixxGetEyePosition(unsmoothed,i,dv)
% DatapixxGetEyePosition computes X and Y pixel values from an analog
% joystick via the A-D system on the Datapixx.
%
% GETJOY uses a moving average to smooth data coming from an analog
% joystick. UNSMOOTHED is the unsmoothed analog history.  JOYCALIBRATION
% gives the MIN and MAX voltages for each channel. MOVAV is the number of
% values used in the moving average. q


% range of the joystick/ eyetracker calibration points (defined by the
% condition points

%TODO:
%change to a gain+offset system? maybe integrate into the adc and allow
%to assign the latest sample to a specified variables (using evalc or feval)

rangeVX = dv.trial.datapixx.calibration(2) - dv.trial.datapixx.calibration(1);
rangeVY = dv.trial.datapixx.calibration(4) - dv.trial.datapixx.calibration(3);
flipX = sign(dv.trial.datapixx.calibration(2));
flipY = sign(dv.trial.datapixx.calibration(3)); % cluge jly
sqPixelCalibrateX = 2*dv.trial.display.winRect(3)/rangeVX;
sqPixelCalibrateY = 2*dv.trial.display.winRect(4)/rangeVY;

Datapixx RegWrRd;
% get voltages from the datapixx
v = Datapixx('GetAdcVoltages');

% this is a tweak to remove the updated i in letsgorun
% i = i - 1;





% Subtract correlated noise off of the current voltage measurement.  Since
% the ambient electrical noise affects the other wires in the analog input
% wires, we subtract the mean of these extra measurements from the voltage
% signal.

% if length(unsmoothed) > 5;
%     vnew = v - mean(v(3:16) - mean(unsmoothed(max([1 i-avg_trail+1]):i,3:16)));
% else
% if strcmp(dv.trial.display.dtype , 'lg55')
%      vnew = v - mean(v(3:16));% - mean(unsmoothed(max([1 i-avg_trail+1]):i,3:16)));
% else
vnew(1,1) = v(1,1)*flipX;
vnew(1,2) = v(1,3)*flipY;


if vnew(1,1) > 4.5*flipX && vnew(1,2) < -4.5  % ktz/sjj - fix, so that lost track results in upward motion of eye position, that is not aong the x axis.
    vnew(1,1) = 0;
    vnew(1,2) = 5;
end
% vnew = v;
% end
% end


% compute the voltages that reflect a neutral joystick or eyetracking position
neutralJVX = (dv.trial.datapixx.calibration(1)+dv.trial.datapixx.calibration(2))./2;  % neutral joystick voltage X-direction
neutralJVY = (dv.trial.datapixx.calibration(3)+dv.trial.datapixx.calibration(4))./2;  % neutral joystick voltage Y-direction
% xoffset = 0;
% yoffset = 0;
% convert voltages into pixels with a scaling factor from the middle of the
% screen
xtemp = sqPixelCalibrateX  * (neutralJVX - vnew(1))/rangeVX   + dv.trial.display.winRect(3)/2;
ytemp = sqPixelCalibrateY * (neutralJVY - vnew(2))/rangeVY   + dv.trial.display.winRect(4)/2;

x = xtemp;
y = ytemp;

% % add unsmoothed line
% unsmoothedline = [xtemp,ytemp,v(3:16)];
%
% x = mean(unsmoothed(max([1 i-dv.movav+1]):i,1));
% y = mean(unsmoothed(max([1 i-dv.movav+1]):i,2));

% for troubleshooting
% fprintf('x: %d v(1): %d\r', x, v(1,1))




