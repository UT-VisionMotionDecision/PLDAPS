function flipBitVideoSync(bit)
%pds.datapixx.flipBitVideoSync    flip a bit at the next VSync
%
% pds.datapixx.flipBit flips a bit on the digital out of the Datapixx
% box, at the time the monitor refreshes the next time, but not back.  
%
% NOTE: The Plexon system records only changes from 0 to 1, while the
% Datapixx also records 1 to 0.
%
% (c) kme 2011

Datapixx('SetDoutValues',2^16 + 2^(bit-1))
Datapixx('RegWrRdVideoSync');