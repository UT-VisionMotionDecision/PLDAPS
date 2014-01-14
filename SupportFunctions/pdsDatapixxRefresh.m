function result = pdsDatapixxRefresh(dv)
% result = pdsDatapixxRefresh(dv)
% pdsDatapixxRefresh refreshes voltage outs
% It's possible (and is the case right now using Leor's Analog data
% aquisition code) that the datapixx will end up with voltages on
% its line out out. The TTL pulses is sends can be flipped into an
% up or down state. This hacky code is designed to make sure the
% reward line is in the down state at the end (so as not to drain
% all fluid)

% 12/12/2013 jly wrote it. Functionized version of hacky code that was
%                          previously in runPLDAPS

result = [];
if nargin < 1
    help pdsDatapixxRefresh
end

if dv.useDatapixxbool
    TTLamp = 0;
    DOUTchannel = 3;
    rewardDelay = 0;
    sampleRate = 1000; % Hz
    
    
    bufferData = [TTLamp*ones(1,round(.1*sampleRate)) 0] ;
    maxFrames = length(bufferData);
    
    Datapixx('WriteDacBuffer', bufferData ,0,DOUTchannel);
    
    Datapixx('SetDacSchedule', rewardDelay, sampleRate, maxFrames ,DOUTchannel);
    Datapixx StartDacSchedule;
    Datapixx RegWrRd;
    
    
end