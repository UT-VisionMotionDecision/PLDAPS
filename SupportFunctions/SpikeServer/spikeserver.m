function [] = spikeserver(port, nanport)
% [] = spikeserver(port, eventsonly)
% SPIKESERVER sends plexon spikes over IP to another computer. Open a UDP 
% socket connect to plexon server (locally), then send spike times to 
% server client (on some other machine)
% Written by jly (heavily adapted from code by p. mineault)
% notes: code from xcorr.net uses PL_GETAD() which seems to be depreciated
% in 64-bit mex file provided by plexon
% INPUTS:
%   port - udp port (default is 4333)
%   eventsonly - 0 or 1 (all spikes or just events) 
%   continuous - 0 or 1 (sent spikes as they occur or on client request)
% (c) jly 09.16.2013 - (adapted from spikeserver.m by p. mineault)
% (c) jk  24.03.2015 - updated to receive settings from remote client

    if nargin <2
        nanport=[];%5333
        if nargin < 1
            port = 4333;
        end
    end
    continuous=false;
    eventsonly = 0;

    KbQueueCreate(-1);
    KbQueueStart();
    KbQueueFlush();
    qKey = KbName('q');

    pnet('closeall');

    if ~isempty(port)
        ps=plexonsocket();
        ps.continuous = continuous;
        ps.eventsonly = eventsonly;
        ps=open(ps,port);
    end
    if ~isempty(nanport)
        ns=nansocket();
        ns=open(ns,nanport);
    end

    disp('Waiting for client requests');

    while 1
        %check keyboard
        [~, firstPressQ]=KbQueueCheck(); % fast
        if firstPressQ(qKey)
            if ~isempty(port)
                close(ps)
            end
            if ~isempty(nanport)
                close(ns)
            end
            
            break;
        end

        if ~isempty(port)
           ps=ps.readAndReply();
        end
        if ~isempty(nanport)
            ns=ns.readAndReply();
        end

    end % while loop

    pnet('closeall');
    disp('Server finished.');
end