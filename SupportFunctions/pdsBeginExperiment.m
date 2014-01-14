function [PDS,dv] = pdsBeginExperiment(dv, PDS)
% [PDS,dv] = pdsBeginExperiment(dv, PDS)
% initialize the beginning of time for this experiment
% beginExperiment checks which devices are connected to PLDAPS and gets
% timestamps from each of them and stores them in PDS.timing

% 12/2013 jly wrote it

if ~isfield(PDS, 'timing')
    PDS.timing = [];
end

if isfield(PDS.timing, 'startPTB')
    PDS.timing.experimentStartPTB(numel(PDS.timing.startPTB)+1) = GetSecs; 
else
    PDS.timing.experimentStart = GetSecs; 
end

if Datapixx('IsReady')
    if isfield(PDS.timing, 'startDatapixx')
        PDS.timing.experimentStartDatapixx(numel(PDS.timing.startDatapixx)+1) = Datapixx('GetTime'); 
    else
        PDS.timing.experimentStartDatapixx = Datapixx('GetTime');
    end
end

if isfield(dv, 'el')
    if isfield(PDS.timing, 'startEyelink')
        PDS.timing.experimentStartEyelink(numel(PDS.timing.startEyelink)+1) = Eyelink('TrackerTime');
    else
        PDS.timing.experimentStartEyelink = Eyelink('TrackerTime');
    end
    Eyelink('message', 'BEGINEXPERIMENT');
end

if isfield(dv, 'spikeserver')
    
end