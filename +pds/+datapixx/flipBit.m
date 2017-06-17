function timings=flipBit(bit,trial)
%pds.datapixx.flipBit    flip a bit on the digital out of the Datapixx
%
% pds.datapixx.flipBit flips a bit on the digital out of the Datapixx
% box and back.  
%
% NOTE: This code is optimized to use with the Plexon omniplex system. 
% We are using it it stobe only mode and thus simply forward the command to 
% pds.datapixx.strobe
%
% (c) jk 2015

if nargout==0
    pds.datapixx.strobe(trial,2^(bit-1));
else
    timings=pds.datapixx.strobe(trial,2^(bit-1));
end