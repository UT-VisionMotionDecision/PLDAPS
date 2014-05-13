function [x,y] = datapixxGetEyePositionSlow(dv)
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
rangeVX = dv.calibration(2) - dv.calibration(1);
rangeVY = dv.calibration(4) - dv.calibration(3);
flipX = sign(dv.calibration(2));

sqPixelCalibrateX = 2*dv.disp.winRect(3)/rangeVX;
sqPixelCalibrateY = 2*dv.disp.winRect(4)/rangeVY;


Datapixx RegWrRd
[bufferData, bufferTimetags] = Datapixx('ReadAdcBuffer', 100);
Datapixx StopAdcSchedule
Datapixx('SetAdcSchedule', 0, dv.dp.eyeSamplingRate, dv.dp.bufferSize, dv.dp.eyeChannels, dv.dp.bufferId, dv.dp.maxBufferFrames)
Datapixx StartAdcSchedule

%% 
bufferData(1,:) = bufferData(1,:).*flipX;

%%
% ktz/sjj - fix, so that lost track results in upward motion of eye
% position, that is not aong the x axis.
lostTrackIdx = bufferData(1,:)>4.5*flipX & bufferData(2,:) < -4.5; 
bufferData(1,lostTrackIdx) = 0; 
bufferData(2,lostTrackIdx) = 5; 

% compute the voltages that reflect a neutral joystick or eyetracking position
neutralJVX = (dv.calibration(1)+dv.calibration(2))./2;  % neutral joystick voltage X-direction
neutralJVY = (dv.calibration(3)+dv.calibration(4))./2;  % neutral joystick voltage Y-direction

% xoffset = 0;
% yoffset = 0;
% convert voltages into pixels with a scaling factor from the middle of the
% screen
xtemp = sqPixelCalibrateX  .* (neutralJVX - bufferData(1,:))./rangeVX   + dv.disp.winRect(3)/2;
ytemp = sqPixelCalibrateY .* (neutralJVY - bufferData(2,:))./rangeVY   + dv.disp.winRect(4)/2;


x = (xtemp(end));
y = (ytemp(end)); 

% for troubleshooting
% fprintf('x: %d v(1): %d\r', x, v(1,1))




