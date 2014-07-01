function dv = beginExperiment(dv)
% [PDS,dv] = pdsBeginExperiment(dv, PDS)
% initialize the beginning of time for this experiment
% beginExperiment checks which devices are connected to PLDAPS and gets
% timestamps from each of them and stores them in PDS.timing

% 12/2013 jly   wrote it
% 01/2014 jly   make sure Eyelink is connected before trying to get time
%               from it

% if ~isfield(PDS, 'timing')
%     PDS.timing = [];
% end

%% set version %make sure to also use the git version for finer control of subversions
dv.defaultParameters.pldaps.version.number=4.1;
dv.defaultParameters.pldaps.version.name='casual';
dv.defaultParameters.pldaps.version.logo='http://www.digitalmomblog.com/wp-content/uploads/2012/06/baby-platypus.jpg';


 %multiple sessions not supported for now
% if isfield(PDS.timing, 'startPTB')
%     PDS.timing.experimentStartPTB(numel(PDS.timing.startPTB)+1) = GetSecs; 
% else
    dv.defaultParameters.session.experimentStart = GetSecs; 
% end

if dv.defaultParameters.datapixx.use && Datapixx('IsReady')
%     if isfield(PDS.timing, 'startDatapixx')
%         PDS.timing.experimentStartDatapixx(numel(PDS.timing.startDatapixx)+1) = Datapixx('GetTime'); 
%     else
	dv.defaultParameters.datapixx.experimentStartDatapixx = Datapixx('GetTime');
%     end
end

if dv.defaultParameters.eyelink.use && Eyelink('IsConnected')
%     if isfield(PDS.timing, 'startEyelink')
%         PDS.timing.experimentStartEyelink(numel(PDS.timing.startEyelink)+1) = Eyelink('TrackerTime');
%     else
	dv.defaultParameters.eyelink.experimentStartEyelink = Eyelink('TrackerTime');
%     end
    Eyelink('message', 'BEGINEXPERIMENT');
end

% if isfield(dv, 'spikeserver')
%     
% end