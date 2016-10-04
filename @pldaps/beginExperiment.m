function p = beginExperiment(p)
%beginExperiment    initialize an Exeriment
% p = beginExperiment(p)
% initialize the beginning of time for this experiment
% beginExperiment checks which devices are connected to PLDAPS and gets
% timestamps from each of them and stores them in the devives substructures
% of p.defeaultParameters

% 12/2013 jly   wrote it
% 01/2014 jly   make sure Eyelink is connected before trying to get time
%               from it
% 05/2015 jk    adapted it to pldaps 4.1
% 10/2016 jk    bumped version to 4.2

%% set version. make sure to also use the git version for finer control of subversions
p.defaultParameters.pldaps.version.number=4.2;
p.defaultParameters.pldaps.version.name='openreception';
p.defaultParameters.pldaps.version.logo='http://www.digitalmomblog.com/wp-content/uploads/2012/06/baby-platypus.jpg';


%multiple sessions not supported for now
p.defaultParameters.session.experimentStart = GetSecs; 

if p.defaultParameters.datapixx.use && Datapixx('IsReady')
    p.defaultParameters.datapixx.experimentStartDatapixx = Datapixx('GetTime');
end

if p.defaultParameters.eyelink.use && Eyelink('IsConnected')
	p.defaultParameters.eyelink.experimentStartEyelink = Eyelink('TrackerTime');
    Eyelink('message', 'BEGINEXPERIMENT');
end