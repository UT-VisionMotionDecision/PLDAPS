function clearCalDisplay(dv)
% pds.eyelink.clearCalDisplay(dv)
% subroutine called by pdsEyelinkCalibrate

if nargin < 1
    help pds.eyelink.calibrate
end

if dv.trial.display.useOverlay
    Screen( 'FillRect',  dv.disp.overlayptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.disp.ptr);
else
    Screen( 'FillRect',  dv.disp.ptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.disp.ptr);
end

