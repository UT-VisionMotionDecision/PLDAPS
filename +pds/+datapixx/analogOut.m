function analogOut(open_time, chan, TTLamp) 
%datapixxanalogOut    Send a TTL pulse through the Analog Out
% Send a [TTLamp] volt signal out the channel [chan], for [open_time] seconds
% 
% Datapixx must be open for this function to work. 
%
% INPUTS:
%	      open_time - seconds to send signal (default = .5)
%              chan - channel on datapixx to send signal 
%                     (you have to map your breakout board [3 on huk rigs])
%            TTLamp - voltage (1 - 5 volts can be output) defaults to 3
% 
%
% written by Kyler Eastman 2011
% modified by JLY 2012 - replaced if~exist with nargin calls for speedup
% modified by JK  2014 - slight adjustments for use with version 4.1

if nargin < 3
    TTLamp = 3; 
    if nargin < 2
        chan = 3; % default reward channel on Huk lab rigs 
        if nargin < 1
            open_time = .5; 
        end
    end
end
    

DOUTchannel = chan; % channel -- you have to map your breakout board

sampleRate = 1000; % Hz MAGIC NUMBER??


bufferData = [TTLamp*ones(1,round(open_time*sampleRate)) 0] ;
maxFrames = length(bufferData);

Datapixx('WriteDacBuffer', bufferData ,0 ,DOUTchannel);

Datapixx('SetDacSchedule', 0, sampleRate, maxFrames ,DOUTchannel);
Datapixx StartDacSchedule;
Datapixx RegWrRd;


