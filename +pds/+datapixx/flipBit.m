function timings=flipBit(bit)
% pds.datapixx.flipBit(bit)
%
% DatapixxFlipBit flips a bit on the digital out values of the Datapixx
% box.  The bit flipped is specified ordinally, so if "bit" = 3, 
% the third bit is set to 1, and quickly set back to zero. 
%
% NOTE: This code if to use with the Plexon omniplex system. 
% We are using it it stobe only mode and thus simply forward the command to 
% pds.datapixx.stobe
%
% (c) jk 2015

if nargout==0
    pds.datapixx.strobe(2^(bit-1),false);
else
    timings=pds.datapixx.strobe(2^(bit-1),false);
end