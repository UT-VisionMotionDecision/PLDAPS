function p = finish(p)
%pds.plexon.finish   finish up plexon after the expeiment
%
% p = pds.plexon.stop(p)
% currently only disconnects the spikeserver
%
% jk wrote it 2015

p = pds.plexon.spikeserver.disconnect(p);