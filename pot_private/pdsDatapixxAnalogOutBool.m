function datapixxAnalogOutBool(useDataPixxBool, DacChList, openCh, amp) 
% 
%   DatapixxAnalogOutBool(useDataPixxBool, DacChList, openCh, [amp])
% 
% Opens the channels (openCh=1) or closes them (openCh=0)
%
%
if ~exist('useDataPixxBool', 'var'), useDataPixxBool = 1;     end
if ~exist('DacChList', 'var'),       DacChList       = [0 1 2 3]; end

% signal amliptude (1-5volts)
if ~exist('amp', 'var'),      amp = 2; end 


numBufferFrames = 1;
sampleRate = 1000;          % Hz
maxFrames  = 0; 


if openCh
    bufferData = repmat(amp, length(DacChList), 1);
else
    bufferData = zeros(length(DacChList), 1);
end



if useDataPixxBool
    Datapixx('WriteDacBuffer', bufferData ,0 ,DacChList);  
    Datapixx('SetDacSchedule', 0, sampleRate, maxFrames ,DacChList, 0, numBufferFrames);
    Datapixx StartDacSchedule;
    Datapixx RegWrRd;
end


 