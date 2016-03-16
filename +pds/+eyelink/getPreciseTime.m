function out=getPreciseTime(optMinwinThreshold,maxTimeThreshold,syncmode)
%pds.eyelink.getPreciseTime    get a rough estimate about the eyelink time
%
% This function is meant to be analogous to the PsychDatapixx('getPreciseTime')
% However the times sr-research provides are already estimates (and bad ones at that)
% while this is still good for synchronizing the clocks, the third output
% should be ignored. 
%
% jk wrote it 2014
    if nargin<3
        syncmode=2;
    end
    if nargin<2
        maxTimeThreshold=0.5;
    end
    if nargin<1
        optMinwinThreshold=0;
    end
    
    if maxTimeThreshold>120
        error('Pds: Eyelink: getPreciseTime: choose a lower maxTimeThreshold or comment this line out. Your are risking a deadlick since this is running at maximum priority.')
    end
    
    oldPriority=Priority;
    if oldPriority < MaxPriority('GetSecs')
            Priority(MaxPriority('GetSecs'));
    end

    stopTime=GetSecs + maxTimeThreshold;

    t=nan(3,1000);
    ic=0;
    minwin=Inf;
    minIdx=0;
    ranOnce=false;
    while((GetSecs<stopTime && minwin>optMinwinThreshold)|| ~ranOnce)

        ic=ic+1;
        WaitSecs(rand / 1000);
        t(1,ic)=GetSecs;
        Eyelink('RequestTime');
%         t(3,ic)=Eyelink('TrackerTime');
        t(2,ic)=GetSecs;

        while (GetSecs < t(2,ic)+1)
            t(3,ic) = Eyelink('ReadTime')/1000;
            if t(3,ic)~=0
                break;
            end
        end
        
        if t(2,ic)-t(1,ic) < minwin
            minwin=t(2,ic)-t(1,ic);
            minIdx=ic;
        end
        ranOnce=true;
    end

    if Priority ~= oldPriority
            Priority(oldPriority);
    end
    
    %check PsychDataPixx:getPreciseTime for more info
    switch syncmode 
        case 2          
            getsecs=(t(2,minIdx)+t(1,minIdx))/2;
            trackertime=t(3,minIdx);
            precision=minwin;
        case 1
            [~, idx] = min(t(2,:) - t(3,:));
            getsecs = t(2,idx);
            trackertime=t(3,idx);
            precision=t(2,idx)-t(1,idx);
        case 0
            [~, idx] = max(t(1,:) - t(3,:));
            getsecs = t(1,idx);
            trackertime=t(3,idx);
            precision=t(2,idx)-t(1,idx);
        otherwise
            error('Pds: Eyelink: getPreciseTime: Unknown timestamping method provided!!');
    end
    
%    out=[getsecs trackertime precision];
    out=[getsecs trackertime NaN];

    
