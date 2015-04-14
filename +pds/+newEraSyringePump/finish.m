function p = finish(p)

if p.trial.newEraSyringePump.use
    IOPort('close',p.trial.newEraSyringePump.h)
end