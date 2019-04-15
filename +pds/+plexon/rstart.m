function [ts] = rstart(logicalState, varargin)
% timings = pds.plexon.rstart(word)
% 
% Set RSTART pin via (24-bit) datapixx digital outputs
% RSTART pin may depend on pinout of particular datapixx-to-Plexon event cable config.
% ...for whatever reason, our standard cable ties RSTART to Datapixx output pin 18 (==2^17)
% 
% Optional outputs:
% [ts]      timestamps [1-by-2] for the strobed event:
%           (1) PTB clock time, (2) Datapixx clock time
% 
% NOTE:
%   Assumes Datapixx is active.
%   Check hardware constraints of recording system to ensure sufficient magnitude,
%   duration, and interval for strobed words will be reliably detected downstream.
%       -- Plexon Omniplex-User-Guide.pdf, sec9.1 p252
%       -- Plexon MAP_Digital_Input_guide.pdf, p10
% 
%   Requesting timestamp outputs requires additional io & computation that
%   may lengthen execution time. Consider your needs. If only being used for
%   signaling events (not syncing clocks), returning timestamps may not be
%   of any acutal benefit in your analysis.
%
% 2019-04-03 TBC    Coded based on pds.datapixx.strobe & cable/plexon tests
% 

%% setup
if nargin > 2
    % alternate rstart pin (shouldn't be necessary)
    if isnumeric(varargin{1})
        % If two numeric inputs, second is RSTART pin value
        rstartMask = 2^varargin{1};
    else
        warning('pldaps:pds:datapixx:badStrobeValues', 'I don''t like your datapixx.strobe inputs.')
    end
else
    rstartMask = 2^17;
end


%% Do the strobing
% Do it fast!!
t0 = GetSecs;
% Set rstart bit value (effective immediately)
Datapixx('SetDoutValues', logicalState*rstartMask, rstartMask);
Datapixx('RegWr');

% Leave pin in active/inactive logicalState
% ...RSTART/RSTOP is based on a level input, not a trigger signal

if nargout==0
    % Wait a fraction of a ms for signal to register downstream
    WaitSecs('UntilTime', t0 + 0.00015);
    
    % Done! Return without assigning output arguments
    return
    
else
    % Slow & wordy...
    % Additional timestamp requests & checks must be interleaved
    % into the typical strobed word transmission process

    % Tell Datapixx this is a time to remember
    Datapixx('SetMarker');
    % transmit and
    Datapixx('RegWrRd'); % also read from datapixx box
    
    % Readout the marker timestamp
    dpTime = Datapixx('GetMarker');
        
    % Package timestamps for output
    ts = [t0, dpTime];
    
end