function timings=flipBit(bit,trial)
%pds.datapixx.flipBit    flip a bit on the digital out of the Datapixx
%
% pds.datapixx.flipBit flips a bit on the digital out of the Datapixx
% box and back.  
%
% THIS FUNCTION IS DEPRECATED: See pds.datapixx.strobe for up-to-date
% event sync signaling with the Plexon omniplex system. 
% Usage of this function will forward to pds.datapixx.stobe, and trigger
% a legacy execution for now, but that functionality may eventually be
% eliminated.
%
% jk 2015
% 2018-05-29 TBC  Warn of deprecation.

% do the warning
persistent beenWarned %#ok<*TLEV>
if ~beenWarned
    warning('pldaps:pds:datapixx:flipBit', 'Use of pds.datapixx.flipBit is outdated.\nUpdate usage to pds.datapixx.strobe posthaste, or else.')
    beenWarned = true;
end

% forward inputs to pds.datapixx.strobe for legacy execution
if nargout==0
    pds.datapixx.strobe(trial, 2^(bit-1));
else
    timings=pds.datapixx.strobe(trial, 2^(bit-1));
end