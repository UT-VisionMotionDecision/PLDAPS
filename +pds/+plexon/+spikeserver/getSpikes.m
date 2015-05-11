function [p, spikes] = getSpikes(p)
%pds.plexon.spikeserver.getSpikes   get data from the spikeserver
%
% p = pds.plexon.spikeserver.getSpikes(p)
% reads spikes from the udp connection 
% can also read the filename of the recorded plexon datafile
% and the location of a nan drive connected to the same machine as the
% spike server
%
spikes = [];
if p.trial.plexon.spikeserver.use
    [spikes, sock, other] = udpGetData(p.trial.plexon.spikeserver.selfip,p.trial.plexon.spikeserver.selfport,p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport,p.trial.plexon.spikeserver.sock, p.trial.plexon.spikeserver.t0);
    p.trial.plexon.spikeserver.sock = sock;
    
    if ~isempty(spikes)
        p.trial.plexon.spikeserver.spikes(p.trial.plexon.spikeserver.spikeCount+1:p.trial.plexon.spikeserver.spikeCount+size(spikes,1),:)=spikes;
        p.trial.plexon.spikeserver.spikeCount=p.trial.plexon.spikeserver.spikeCount+size(spikes,1);
    end
    if ~isempty(other.filename)
        if strcmp(other.filename,'NOTRECORDING')
            warning('pds:plexon:spikeserver:getSpikes', 'Spikeserver enabled, but the Plexon machine does not store the data!');
        else
            fprintf('SPIKESERVER-INFO Plexon Filename: %s\n',other.filename);
        end
        p.trial.plexon.filename = other.filename;
    end
    if ~isempty(other.nanpositions) %got a nan position a well
        
        p.trial.plexon.nanpositions = [p.trial.plexon.nanpositions; other.nanpositions];
    end
end