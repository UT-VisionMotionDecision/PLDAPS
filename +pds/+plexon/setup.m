function p = setup(p)
%pds.plexon.setup   setup up plexon before the expeiment
%
% p = pds.plexon.setup(p)
% currently only connects the spikeserver
%
% jk wrote it 2015

p = pds.plexon.spikeserver.connect(p);