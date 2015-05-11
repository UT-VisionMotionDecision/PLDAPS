function p = finish(p)
%pds.newEraSyringePump.finish   closes the IO Port to the pump
%
% typically called at the end of the experiment
%
% p = pds.newEraSyringePump.finish(p)
%
% jk wrote it 2015

if p.trial.newEraSyringePump.use
    IOPort('close',p.trial.newEraSyringePump.h)
end