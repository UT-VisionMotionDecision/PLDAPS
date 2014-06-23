function flipBit(bit)
% pds.datapixx.flipBit(bit)
%
% DatapixxFlipBit flips a bit on the digital out values of the Datapixx
% box, provided USEDATPIXXBOOL = 1.  The bit flipped is specified
% ordinally, so if "bit" = 3, the third
% bit is set to 1, and quickly set back to zero. 
%
% NOTE: The Plexon system records only changes from 0 to 1, while the
% Datapixx also records 1 to 0.
%
% (c) kme 2011


Datapixx('SetDoutValues',2^(bit-1))
Datapixx('RegWrRd');
Datapixx('SetDoutValues',0)
Datapixx('RegWrRd');
