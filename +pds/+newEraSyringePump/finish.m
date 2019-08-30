function finish(p)
%pds.newEraSyringePump.finish   closes the IO Port to the pump
%
% typically called at the end of the experiment
%
% p = pds.newEraSyringePump.finish(p)
%
% jk wrote it 2015
% 2019-04-11  TBC  Return nothing. Try not to crash completely if port already closed

if p.trial.newEraSyringePump.use
    try
        IOPort('close',p.trial.newEraSyringePump.h)
    end
end
