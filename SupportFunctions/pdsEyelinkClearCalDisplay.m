function pdsEyelinkClearCalDisplay(dv)

if dv.disp.useOverlay
    Screen( 'FillRect',  dv.disp.overlayptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.disp.ptr);
end

