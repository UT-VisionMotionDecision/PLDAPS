function timings=strobe(word)
% DataPixxStrobe(word)
% strobes a single 8-bit word (255) from the datapixx
% INPUTS
%   useDataPixxBool - logical 
%   word            - 8-bit word to strobe from Datapixx
% This function takes approximately 2ms to run
%
% (c) kme 2011
% jly 2013


% Datapixx('SetDoutValues',bin2dec(['1' dec2bin(word,8) '00000000']))
if nargout==0
    Datapixx('SetDoutValues',(2^8+word)*2^8);
    Datapixx('RegWrRd');
    Datapixx('SetDoutValues',0)
    Datapixx('RegWrRd');
else
    t=nan(2,1);
    oldPriority=Priority;
    if oldPriority < MaxPriority('GetSecs')
            Priority(MaxPriority('GetSecs'));
    end

    Datapixx('SetDoutValues',(2^8+word)*2^8);
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