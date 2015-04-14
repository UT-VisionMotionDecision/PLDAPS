function p = give(p, amount)

    if p.trial.newEraSyringePump.use
        if nargin <2 %repeat last given Volume
            IOPort('Write', p.trial.newEraSyringePump.h, ['RUN' p.trial.newEraSyringePump.commandSeparator],0);
        else
%             IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' num2str(amount) p.trial.newEraSyringePump.commandSeparator],0);
%             IOPort('Write', p.trial.newEraSyringePump.h, ['RUN' p.trial.newEraSyringePump.commandSeparator],0);
            IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' sprintf('%3.3f',amount) p.trial.newEraSyringePump.commandSeparator 'RUN' p.trial.newEraSyringePump.commandSeparator],0);
        end
    end

% 
%     if p.trial.behavior.reward.dataPixxAnalog.use
%          pds.datapixx.analogOut(rt);
%     end

    % IOPort('Write', h, ['RAT 2900 MH ' char(13)],0);



    %%sound

    %%flag