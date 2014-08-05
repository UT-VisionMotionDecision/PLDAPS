function clearCalDisplay(dv)
% pds.eyelink.clearCalDisplay(dv)
% subroutine called by pdsEyelinkCalibrate

if nargin < 1
    help pds.eyelink.calibrate
end

if dv.trial.display.useOverlay
    Screen( 'FillRect',  dv.trial.display.overlayptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.trial.display.ptr);
else
    Screen( 'FillRect',  dv.trial.display.ptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.trial.display.ptr);
end

