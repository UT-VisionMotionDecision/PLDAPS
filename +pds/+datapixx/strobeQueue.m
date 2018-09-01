function [p] = strobeQueue(strobeVals)
% pds.datapixx.strobeQueue(p)
% 
% Schedule a datapixx strobed word to be sent by pldapsDefaultTrialFunction just before next frameFlip.
% -- appends [word] values to end of existing queue
% -- allows multiple strobe values to be sent in rapid succession (need a few tenths of a ms, so execution time btwn sends tends to be enough
%
% 2018-09-30  TBC  Wrote it.

    
% strobe word(s) in strobe queue
for i = 1:numel(strobeVals)
    t0 = GetSecs;
    pds.datapixx.strobe(strobeVals(i));
    % Wait a fraction of a ms for signal to register downstream
    WaitSecs('UntilTime', t0+3e-5);
end
% p.trial.datapixx.strobeQ = [];
