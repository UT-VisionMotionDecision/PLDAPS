function p = refill(p, refillVol)
%
% Still very beta & risky...not for use by mere mortals.
% 
% 2019-02-14  TBC  Wrote it.

% defaults
if nargin<2 || isempty(refillVol)
    refillVol = 25;
else
    refillVol = ceil(refillVol);
    refillVol(refillVol<0.01) = 0.01; % prevents runaway withdrawal (if vol==0)
end

% local variables & info
refillStr = sprintf('%.2f', refillVol);
xx = p.trial.newEraSyringePump.commandSeparator;
% safety pauses & timing
pdur = [.5, refillVol/(p.trial.newEraSyringePump.rate/60)*1.2];
pollRate = .5;

fprintLineBreak
fprintf(2, 'Refilling syringe pump\n\tVol = %4.2f\t\t(approx %4.2f sec)\n', refillVol, pdur(2)+3)
waitTillFinished(p)
pause( pdur(1) ); tic
[volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
p.trial.newEraSyringePump.volumeGiven = volumeGiven;
p.trial.newEraSyringePump.volumeWithdrawn = volumeWithdrawn;

fprintf('\tVolumeGiven = %4.1f,\t\tVolumeWithdrawn = %4.1f', volumeGiven, volumeWithdrawn);
waitTillFinished(p)
tic

% Reverse pump direction & run desired volume
IOPort('Write', p.trial.newEraSyringePump.h, ['DIR WDR', xx, 'VOL ', refillStr, xx, 'RUN', xx]);

waitTillFinished(p)
pause( pdur(1) );
    %pause( pdur(2) );

% Prime rebound amount (empirical measurement of syringe pump hysteresis/flex)
IOPort('Write', p.trial.newEraSyringePump.h, ['DIR INF', xx, 'VOL 1.3', xx, 'RUN', xx]);
waitTillFinished(p)
pause( pdur(1) );
% Establish correct default reward amount
%   (...manual triggers [foot pedal] merely replay the most recent command)
IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ', sprintf('%.3f',p.trial.behavior.reward.defaultAmount), xx, 'RUN', xx]);
waitTillFinished(p)

[volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
p.trial.newEraSyringePump.volumeGiven = volumeGiven;
p.trial.newEraSyringePump.volumeWithdrawn = volumeWithdrawn;

fprintf([repmat('\b',[1,6]),'%4.1f\t\tDone\n.'], volumeWithdrawn);
toc

fprintLineBreak;


%% Nested Functions % % %

    %% waitTillFinished(p) 
    function waitTillFinished(p)
        % wait till stopped
        while pds.newEraSyringePump.isActive(p)
            pause( pollRate )
        end
    end
end %main function
