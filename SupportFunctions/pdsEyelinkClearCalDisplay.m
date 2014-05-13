function pdsEyelinkClearCalDisplay(dv)

if dv.trial.display.useOverlay
    Screen( 'FillRect',  dv.trial.display.overlayptr, 0);	% clear_cal_display()
    Screen( 'Flip',  dv.trial.display.ptr);
end

