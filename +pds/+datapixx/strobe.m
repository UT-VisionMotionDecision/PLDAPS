function timings=strobe(word, addOffset)
% DataPixxStrobe(word)
% strobes a single 8-bit word (255) from the datapixx
% INPUTS
%   useDataPixxBool - logical 
%   word            - 8-bit word to strobe from Datapixx
% This function takes approximately 2ms to run
%
% (c) kme 2011
% jly 2013

if nargin < 2 || ~addOffset
    word=mod(word*2^8, 2^16);
end

if nargout==0
    %first we set the bits without the strobe, to ensure they are all
    %settled when we flip the strobe bit (plexon need all bits to be set
    %100ns before the strobe)
    Datapixx('SetDoutValues',word);
    Datapixx('RegWrRd');
    
    %now add the strobe signal. We could just set the strobe with a bitmask,
    %but computational requirements are the same (due to impememntation on
    %the Datapixx side)
    Datapixx('SetDoutValues',2^16 + word);
    Datapixx('RegWrRd');
    
    %Not required for plexon communication, but good practice: set to zero
    %again
    Datapixx('SetDoutValues',0)
    Datapixx('RegWrRd');
else
    t=nan(2,1);
    oldPriority=Priority;
    if oldPriority < MaxPriority('GetSecs')
            Priority(MaxPriority('GetSecs'));
    end
    Datapixx('SetDoutValues',word);
    Datapixx('RegWrRd');

    Datapixx('SetDoutValues',2^16 + word);
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