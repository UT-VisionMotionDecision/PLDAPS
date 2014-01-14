function DatapixxFlipBitVideoSync(bit)
% DatapixxFlipBitVideoSync(bit)
%
% DatapixxFlipBit flips a bit on the digital out values of the Datapixx
% box, at the time the monitor refreshes.  The bit flipped is specified
% ordinally, so if "bit" = 3, the third
% bit is set to 1, and quickly set back to zero. 
%
% NOTE: The Plexon system records only changes from 0 to 1, while the
% Datapixx also records 1 to 0.
%
% (c) kme 2011


Datapixx('SetDoutValues',2^(bit-1))
Datapixx('RegWrRdVideoSync');

% I don't think we need these... -jake
% Datapixx('SetDoutValues',0)
% Datapixx('RegWrRd');
