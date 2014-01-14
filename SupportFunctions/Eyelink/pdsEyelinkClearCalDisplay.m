function pdsEyelinkClearCalDisplay(dv)
% pdsEyelinkClearCalDisplay(dv)
% subroutine called by pdsEyelinkCalibrate

if nargin < 1
    help pdsEyelinkCalibrate
end

if dv.disp.useOverlay
    Screen( 'FillRect',  dv.disp.overlayptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.disp.ptr);
else
    Screen( 'FillRect',  dv.disp.ptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.disp.ptr);
end

