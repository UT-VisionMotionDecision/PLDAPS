function [p] = strobeQueue(strobeVals)
% pds.datapixx.strobeQueue(p)
% 
% Schedule a datapixx strobed word to be sent by pldapsDefaultTrialFunction just before next frameFlip.
% -- appends [word] values to end of existing queue
% -- allows multiple strobe values to be sent in rapid succession, leaving a fraction of a ms for distinct 
%    strobes to be detected downstream.
%    Plexon strobe limits:  [minDuration, minInterval]
%    -- MAP       [2.5e-5,  1.5e-5]     (Omniplex-User-Guide.pdf, sec9.1 p252)
%    -- Omniplex  [1e-7,    5e-9]       (MAP_Digital_Input_guide.pdf, p10)
%
% NOTE:
%   This is a dumb manual sequence of strobes..could probably be done better by scheduling a Dout sequence
%   to strobe queue with appropriate duration & frequency for downstream hardware detection.
% 
% 
% 2018-09-30  TBC  Wrote it.

    
% strobe word(s) in strobe queue
for i = 1:numel(strobeVals)
    t0 = GetSecs;
    pds.datapixx.strobe(strobeVals(i));
    % Wait a fraction of a ms for signal to register downstream
    WaitSecs('UntilTime', t0+1.5e-5);
end
% p.trial.datapixx.strobeQ = [];
