function p = give(p, amount)
% p = pds.newEraSyringePump.give(p, amount)
% 
% Dispense a specified amount of volume
%   (default = same as last volume given)
% 
%   ** Avoids reward volume = 0, which pump interprets as continuous pumping(!)
%   ** Crufty volume string format conversion to adhere to syringe pump protocol:
%       "Maximum of 4 digits plus 1 decimal point [&&] Maximum of 3 digits to right of decimal point"
% 
% jk wrote it 2015
% 2019-02-08  TBC  cleaned
% 2019-02-14  TBC  commented

% Make shorthand  (repeated calls to params class is a real drag)
NES = p.trial.newEraSyringePump;

if NES.use
    if nargin <2
        % repeat last given Volume
        IOPort('Write', NES.h, ['RUN' NES.commandSeparator],0);
        
    elseif amount>=0.001 && amount<=9999
        IOPort('Write', NES.h, ['VOL ' sprintf('%*.*f', ceil(log10(amount)), min(3-ceil(log10(amount)),3),amount), NES.commandSeparator,...
                                'RUN' NES.commandSeparator], 0);
    end
end

end %main function