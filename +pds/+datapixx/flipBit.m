function timings=flipBit(bit)
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

if nargout==0
    Datapixx('SetDoutValues',2^(bit-1))
    Datapixx('RegWrRd');
    Datapixx('SetDoutValues',0)
    Datapixx('RegWrRd');
else
    t=nan(2,1);
    oldPriority=Priority;
    if oldPriority < MaxPriority('GetSecs')
            Priority(MaxPriority('GetSecs'));
    end

    Datapixx('SetDoutValues',2^(bit-1))
    Datapixx('SetMarker');
    
    t(1)=GetSecs;
    Datapixx('RegWr');
    t(2)=GetSecs;
    
    Datapixx('SetDoutValues',0)
    Datapixx('RegWrRd');
    dpTime=Datapixx('GetMarker');

    if Priority ~= oldPriority
            Priority(oldPriority);
    end
    
    timings=[mean(t) dpTime diff(t)];
end