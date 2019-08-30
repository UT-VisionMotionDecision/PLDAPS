function clearDisplay(p)
% function clearDisplay(p)
% pds.eyelink.cal.clearDisplay    
% clears the display


% if p.trial.display.useOverlay
%     Screen( 'FillRect',  p.trial.display.overlayptr, 0);	% clear_cal_display()
%     Screen( 'Flip',  p.trial.display.ptr);
% else
    Screen( 'FillRect',  p.trial.display.ptr, p.trial.display.bgColor);	% clear_cal_display()
    Screen( 'Flip',  p.trial.display.ptr, 0);
end

