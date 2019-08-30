function [p] = write(p, data, showMsg)
% function [p] = pds.newEraSyringePump.write(p, data, showMsg)
%
% Dead simple write/read interaction with newEraSyringePump via IOPort commands
% 
%   [p]         pldaps struct containing field p.trial.newEraSyringePump; or just handle to syringe pump
%   [data]      string of data to write (can contain multiple lines (CR), but must be less than 128 char for now...)
%   [showMsg]   1=print to cmd window, 0=read & return in msgOut only, -1=don't read just write and move on
% 
% CAUTION: this uses 'blocking' writes & reads that could/will interfere with timing if called during trial execution.
% 
% 
% 2017-01-25  TBC  Wrote it.
% 2017-03-27  TBC  Cleaned it.
% 2017-10-24  TBC  Converted to module
% 2017-04-25  TBC  Adapted from Grbl controller module

if nargin<3 || isempty('showMsg')
    showMsg = 0; 
end

if isobject(p) || isstruct(p)
    % passed in full PLDAPS struct/obj
    H = p.trial.newEraSyringePump.h;
    
elseif ishandle(p)
    % only passed handle to open serial port
    H = p;
end

% ensure command ends with proper terminal character, CR ('\r')
if data(end)~= (1* sprintf('\r'))
    data(end+1) = 1* sprintf('\r');
end


IOPort('write', H, uint8([1*data]), 1);    % H.portTerm]))

msgOut = []; err = [];
if showMsg>=0
    % Need a brief pause to let IO commands be processed/returned or things get garbled & fail.
    pause(.05)
    toread = IOPort('bytesAvailable',H);
    while toread>0
        % caution, this is a 'blocking read' that could/will interfere with timing if run during trial execution
        [msg, msgTime, err] = IOPort('read', H, 1, toread);
        msgOut = [msgOut, char(msg)];
        toread = IOPort('bytesAvailable', H);
    end
    
    % Stop immediately if error
    if err
        fprintf(2, '\tFailed write to pump (h=%i, data=%s), response:  %s\n', H, data, msg);
        return;
    end
    
    % Display response in command window
    if showMsg && ~isempty(msgOut)
        fprintf([msgOut, '\n'])
    end
    
    % Manage outputs
    if nargout>0
        if isobject(p)
            if isfield(p.trial.newEraSyringePump, 'msg')
                p.trial.newEraSyringePump.msg(end+1, 1:2) = {msgOut, msgTime};
            else
                p.trial.newEraSyringePump.msg = {msgOut, msgTime};
            end
        elseif ~evalin('caller', sprintf('isobject(%s);', inputname(1)))
            % ...might be slow, but ensures we don't overwrite the main pldaps object by accident
            p = {msgOut, msgTime};
        end
    end
end

end