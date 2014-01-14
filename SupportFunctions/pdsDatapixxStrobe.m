function DatapixxStrobe(word)
% DataPixxStrobe(word)
% strobes a single 8-bit word (255) from the datapixx
% INPUTS
%   useDataPixxBool - logical 
%   word            - 8-bit word to strobe from Datapixx
% This function takes approximately 2ms to run
%
% (c) kme 2011
% jly 2013


Datapixx('SetDoutValues',bin2dec(['1' dec2bin(word,8) '00000000']))
Datapixx('RegWr');
Datapixx('SetDoutValues',0)
Datapixx('RegWr');
