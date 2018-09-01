function [ts, tsDiff] = strobe(word, varargin)
% timings = pds.datapixx.strobe(word)
% 
% Strobe a single (15-bit) word through the (24-bit) datapixx digital outputs
% to be recorded by ephys [typically Plexon] system for syncing & trial events
% 
% Optional outputs:
% [ts]      timestamps [1-by-2] for the strobed event:
%           (1) PTB clock time (estimate), (2) Datapixx clock time
% [tsDiff]  1-by-2 values for examining timestamp offsets/accuracy
%           (1) diff of PTB & Datapixx clock values
%           (2) diff of two PTB clock samples used for estimating PTB time
%           (...these diffs are pretty nitpicky, and really just here for debugging)
% 
% NOTE:
%   Requesting timestamp outputs requires additional io & computation that
%   may lengthen execution time. Consider your needs. If only being used for
%   signaling events (not syncing clocks), returning timestamps may not be
%   of any acutal benefit in your analysis.
%
% ==================
% LEGACY USAGE:  (not recommended)
% pds.datapixx.strobe(lowWord,highWord)
% strobes two 8-bit words (255) from the datapixx
% INPUTS
%   lowWord            - bits 0-7 to strobe from Datapixx
%   highWord           - bits 8-15 to strobe from Datapixx
% OUTPUTS
%   timings            - precise timing estimates of the time of the strobe
% ==================
% 
% (c) kme 2011
% jly 2013
% jk 2015 changed to work with the plexon omiplex system
% 2018-05-29 TBC    Updated to transmit native 15-bit words for event and
%                   trial unique_numbers. Strobed values can be readout 
%                   directly from Plexon [.plx/.pl2] files.
% 

% Legacy stuff
if nargin > 1
    if isnumeric(varargin{1})
        % If two numeric inputs, assume legacy usage as two 8-bit words,
        % & stack them into a single 16-bit word for transmission.
        word = mod(word, 2^8) + mod(varargin{1}, 2^8)*2^8;
    else
        warning('pldaps:pds:datapixx:badStrobeValues', 'I don''t like your datapixx.strobe inputs.')
    end
end

%% setup
% Omniplex records strobed values only when the 16th bit is flipped true
strobeBit = 16;
% Use bitmask so we don't inadvertently alter other channels/functions
%   i.e.  mask == 2^16 == dec2bin(2^16, 24) == 000000010000000000000000
strobeMask = 2^strobeBit;
wordMask = 2^strobeBit-1;

%% Do the strobing
if nargout==0
    % Do it fast!!
% % %     for i = 1:numel(word)
        t0 = GetSecs;
        % Set word bit values first
        Datapixx('SetDoutValues', word, wordMask);
        Datapixx('RegWr');
        
        % Send strobe signal to trigger recording by Plexon
        Datapixx('SetDoutValues', 2^strobeBit, strobeMask);
        Datapixx('RegWr');
        
        % Wait a fraction of a ms for signal to register downstream
        WaitSecs('UntilTime', t0+2e-5);
% % %     end
    
    % Best practice to zero out all bits after transmission
    Datapixx('SetDoutValues', 0, wordMask+strobeMask)
    Datapixx('RegWr');
    
    % Done! Return without setting output arguments
    return
    
else
    % Slow & wordy...
    % Additional timestamp requests & checks must be interleaved
    % into the typical strobed word transmission process

    % Ensure real-time priority (...may itself be a time sink)
    oldPriority=Priority;
    if oldPriority < MaxPriority('GetSecs')
        Priority(MaxPriority('GetSecs'));
    end
    
    % pre-allocate
    t = nan(2, 1);
% % %     dpTime = t(1,:);
    
    
% % %     for i = 1:numel(word)
% % %         t0 = GetSecs;
        
        % Set word bit values first, to ensure they are all settled
        % (plexon need all bits to be set/settle for 100ns before the strobe)
        Datapixx('SetDoutValues', word, wordMask);
        Datapixx('RegWr');

        % Then, send strobe signal on the highest receiving bit (16th) of the
        % omniplex system. 2nd input masks out other values of Datapixx's 24bit
        % outputs so that all lower 'word bits' remain untouched.
        Datapixx('SetDoutValues', 2^strobeBit, strobeMask);

        % Tell Datapixx this is a time to remember
        Datapixx('SetMarker');

        % Flank strobe transmission with PTB clock samples
        t(1)=GetSecs;
        Datapixx('RegWr');
        t(2)=GetSecs;

        % Best practice to zero out all bits after transmission
        Datapixx('SetDoutValues', 0, wordMask+strobeMask)
        Datapixx('RegWrRd'); % also read from datapixx box

        % Readout the marker timestamp
        dpTime = Datapixx('GetMarker');
        
% % %         % Wait a fraction of a ms for signal to register downstream
% % %         WaitSecs('UntilTime', t0+2e-5);
% % %     end
    
    % Return priority to previous setting
    if Priority ~= oldPriority
        Priority(oldPriority);
    end
    
    % Package timestamps for output
    ts = [mean(t)', dpTime'];
    tsDiff = [diff(ts'); diff(t)]';
    
end