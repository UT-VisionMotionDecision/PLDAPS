% Clock sync routine: Synchronizes host clock (aka GetSecs time) to box
% internal clock via a sampling and calibration procedure:
function syncresult = syncClocks(syncSettings)
    
    if nargin<1
        % Initialize a PLDAPS object containing class & rig defaults
        p = pldaps('test','nothing');
        syncSettings = p.datapixx.GetPreciseTime;
        
        % Only mess with priority if nothing passed as input, otherwise
        % assume PLDAPS has already taken care of maximizing Priority
        oldPriority=Priority;
        if oldPriority < MaxPriority('GetSecs')
            Priority(MaxPriority('GetSecs'));
        end
        
    end
    % Default return argument to "invalid":
    %[hosttime, boxtime] = deal(nan);
    syncresult = nan(1,3);
    
    % Query level of verbosity to use:
    verbosity = 0;  %syncSettings.verbosity;

    % Maximum allowable minwin is 1.3 msecs, the expected maximum for an ok
    % but not great USB write transaction:
    maxMinwinThreshold = 0.0013;

    % Perform multiple measurement trials per syncClocks run, take the best
    % one for final result. We use the "best" one because we have a good
    % criterion to find the best one.
    
    % We preallocate the sampling arrays for 250 samples at most. The
    % arrays will grow if 250 samples are not sufficient, at a small
    % performance penalty:
    ntrials = 250;
            
% %     % Switch to realtime priority if not already there:
% %     oldPriority=Priority;
% %     if oldPriority < MaxPriority('GetSecs')
% %         Priority(MaxPriority('GetSecs'));
% %     end
    
    t = zeros(3,ntrials);
    minwin = inf;
    tdeadline = GetSecs + syncSettings.maxDuration;
    ic = 0;
    
    % Perform measurement trials until success criterion satisfied:
    % Either a sample with a maximum error 'minwin' less than desired
    % threshold, or maximum allowable calibration time reached:
    while (minwin > syncSettings.optMinwinThreshold) && (GetSecs < tdeadline)
        % Prepare clock query:
        Datapixx('SetMarker');

        % Wait some random fraction of a millisecond. This will desync us
        % from the USB duty cycle and increase the chance of getting a very
        % small time window between scheduling, execution and acknowledge
        % of the send operation:
        WaitSecs(rand / 3000);
        
        % Take pre-Write timestamp in tpre - Sync command not emitted
        % before that time:
        tpre = GetSecs;
        
        % Emit immediate register writecommand:
        Datapixx('RegWr');
        
        % Store completion time in post-write timestamp tpost:
        tpost = GetSecs;
        
        % We know that write command emission has happened at some time
        % after tpre and before tpost. This by design of the USB
        % standard, host controllers and operating system USB stack. This
        % is the only thing we can take for granted wrt. timing, so the
        % "time window" between those two timestamps is our window of
        % uncertainty about the real host time when sync started. However,
        % on a well working system without massive system overload one can
        % be reasonably confident that the real emission of the sync
        % command happened no more than 1 msec before tpost. That is a
        % soft constraint however - useful for computing the final estimate
        % for hosttime, but nothing to be taken 100% for granted.
        
        % Retrieve latched 'SetMarker' timestamp from box, by first reading
        % back the register block, then getting the latched marker value:
        Datapixx('RegWrRd');
        tbox = Datapixx('GetMarker');

        % Compute confidence interval for this sample:
        % For each measurement, the time window tpost - tpre defines a
        % worst case confidence interval for the "real" host system time
        % when the sync command was emitted.
        confidencewindow = tpost - tpre;
        
        % If the confidencewindow is greater than the maximum acceptable
        % window, then we reject this sample, else we accept it. 
        if confidencewindow <= maxMinwinThreshold
            % Within acceptable range. Accept this sample and check if it
            % is the best wrt. to window size so far:
            if confidencewindow < minwin
               % Best confidencewindow so far. Update minwin, as this is one
               % of the abortion critera:
               minwin = confidencewindow;
            end
            
            % Increase sample index to permanently accept this sample for
            % final set of competitors:
            ic = ic + 1;
            
            % Assign values:
            t(1,ic) = tpre;
            t(2,ic) = tpost;
            t(3,ic) = tbox;
        else
            % Inacceptably large error confidencewindow. Reject this sample:
            continue;
        end

        % Next sample pass:
    end

    % Done with sampling: We have up to 'ic' valid samples, unless minwin
    % is still == inf.
    
    if nargin<1
        % Restore priority to state pre syncClocks:
        if Priority ~= oldPriority
            Priority(oldPriority);
        end
    end
    
    % At least one sample with acceptable precision acquired?
    if (minwin > maxMinwinThreshold) || (ic < 1)
        % No, not even a single one!
        if verbosity > 1
            fprintf('PsychDataPixx: Warning: On Datapixx, pds.datapixx.syncClocks failed due to confidence interval of best sample %f secs > allowable maximum %f secs.\n', minwin, maxMinwinThreshold);
            fprintf('PsychDataPixx: Warning: Likely your system is massively overloaded or misconfigured!\n');
            fprintf('PsychDataPixx: Warning: Consider relaxing PLDAPS parameters for .datapixx.GetPreciseTime\n');
        end
        
        % That's it:
        return;
    end

    % Ok, we have 'ic' > 0 samples with acceptable precision, according to
    % user specified constraints. Prune result array to valid samples 1 to ic:
    t = t(:, 1:ic);

    % ==== .syncmode no longer selectable ====
    % ==== mode 1 is the default ====
    % No empirical difference between syncmodes has shown itself. Lets not
    % waste experiment time hemming & hawing over which one to use.
    % See original PsychDataPixx('GetPreciseTime') for details & full
    % description of [prior] alternatives/justifications. 
    
    % PsychDataPixx "New style method 1" - Postwrite timestamps:
    % ==> Select sample with minimum t(2,:) - t(3,:) as final best result:
    [~, idx] = min(t(2,:) - t(3,:));
    
    % Host time corresponds to tpost write timestamp, which should be as
    % close as possible to real host send timestamp:
    hosttime = t(2,idx);
    
    % Box timers time taken "as is":
    boxtime  = t(3,idx);
    
    % Recalculate upper bound on worst case error 'minwin' from this best
    % samples tpost - tpre:
    minwin = t(2,idx) - t(1,idx);

    if verbosity > 3
        fprintf('PsychDataPixx: pds.datapixx.syncClocks on Datapixx box: Got %i valid samples, maxconfidence interval = %f msecs, winner interval %f msecs.\n', ic, 1000 * maxMinwinThreshold, 1000 * minwin);
        fprintf('PsychDataPixx: Confidence windows in interval [%f - %f] msecs. Range of clock offset variation: %f msecs.\n', 1000 * min(t(2,:)-t(1,:)), 1000 * max(t(2,:)-t(1,:)), 1000 * range(t(2,:) - t(3,:)));
    end
    
%     % Assign (host,box,confidence) sample to sync struct:
    syncresult = [hosttime, boxtime, minwin];
        
    % SyncClocks run finished:
end