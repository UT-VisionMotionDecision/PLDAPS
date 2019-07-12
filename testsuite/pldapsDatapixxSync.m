function syncSettings = pldapsDatapixxSync2(p)
%pldapsSyncTests   a script with commands to test the best datapixx timing options
%                  for your system
% 
% Optimal parameters for datapixx clock sync estimates
% might vary across systems/OSes/rigs, thus remain an emprical question.
% This script is meant to help test & apply reasonable parameters.
% Relevant parameters are: syncmode, optMinwinThreshold, and maxDuration.
% 
% 
% [syncmode]
% Old Jonas code recommmended syncmode 2, default is 1...precise meaning of those magic
% numbers may have changed though. Open PsychDatapixx.m and search text for "GetPreciseTime"
% for more/current details. Search text for "dpx.syncmode" for detailed
% descriptions & justifications [from Vpixx] of each syncmode in the comments.
% Empirically, no difference btwn 1 & 2, 0 seems broke in some ways.
% 
% [optMinwinThreshold]
% Minimum precision stopping criterion. Default is zero (always do the best you
% can in the time alotted by maxDuration). ...this test uses it to find out how
% long it takes to reliably compute a given precision.
% 
% [maxDuration]
% Length of time to acquire sample set used for clock sync estimates. By default,
% PsychDatapixx estimates the time delay between the computer and datapixx for
% 0.5 seconds. In real-world tests this seems overly generous (...tends to plateau
% by around 20-30 ms), and may waste time if called frequently. This function aids
% in tuning the duration for your particular system/needs.
% Note: maxDuration does impose a hard limit...don't expect to match a
% multiple of display ifi.
% 
% Recommendations as of 2018:
% syncmode=1; optMinwinThreshold=0; maxDuration=0.03; (sec)
% 

%% From PsychDatapixx help:
% [getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
% - Query both the DataPixx clock and GetSecs clock and compute which GetSecs
% time 'getsecs' corresponds to which Datapixx time 'boxsecs' and how
% reliable this correspondence is in 'confidence'. 'confidence' is the
% margin of error between both timestamps.
% This function implicitely synchronizes both clocks to get more precise
% values for 'getsecstime' from calls to PsychDataPixx('GetLastOnsetTimestamp');
% The function is automatically called once at device open time.

if nargin<1
    % Initialize a PLDAPS object containing class & rig defaults
    p = pldaps('test','nothing');
    syncSettings = p.trial.datapixx.GetPreciseTime;
    
    % Only mess with priority if nothing passed as input, otherwise
    % assume PLDAPS has already taken care of maximizing Priority
    oldPriority=Priority;
    if oldPriority < MaxPriority('GetSecs')
        Priority(MaxPriority('GetSecs'));
    end
    
else
    syncSettings = p.trial.datapixx.GetPreciseTime;
    
end

% Prepare for test
if ~Datapixx('isReady')
    Datapixx('open');
end

    testSettings = syncSettings;
    
    fprintf(2, [fprintLineBreak, 'Begin...\n']);
    
    %% Optimize max duration of samples
    % zero out optimal threshold to ensure maxDuration is the limiting factor for this test
    testSettings.optMinwinThreshold = 0;
    
    % setup sample points
    nsamp = 100;
    nreps = 20;
    %         durLims = [1, nsamp];
    %         durs = linspace(durLims(1), durLims(2), nsamp);
    durLims = [1, 300]; % ms
    durs = logspace(log10(durLims(1)), log10(durLims(2)), nsamp);
    
    % pre-allocate
    durConf = nan(nsamp,1);
    
    % testing loop
    fprintf('Testing maxDurations (est. %2.1f min)\n..',sum(durs.*nreps)/1000/60);
    tic
    for n = 1:nsamp
        
        testSettings.maxDuration = durs(n)/1000; % in sec
        for i = 1:nreps
            [~, ~, durConf(n,i)] = syncClocks(testSettings);
            %   [~, ~, jnk(i)] = PsychDataPixx('GetPreciseTime'); %#ok<SAGROW>
        end
        
        if ~mod(n, 10)
            fprintf('.')
        end
    end
    fprintf('Done. (%2.2f min)\n', toc/60)
    % Plot the 90th prctile for a high baseline estimate of possible timing precision
    durConfMed = prctile(durConf',90);
    
    % Plot dur test results
    if exist('fig1','var')
        figure(fig1);
    else
        fig1 = figure; %#ok<*NASGU>
    end
    semilogx(durs, durConfMed*1000);
    hold on, box off, grid on
    set(gca, 'LineWidth',0.5,...
        'XTick',[1,2,5,10,20,50,100,200,300,400,500]);
    xlim(durs([1,end]).*[.9,1.1]);
    ylim([.01, .45])
    xlabel('Sync duration (ms; maxDuration)');
    ylabel('Resulting precision (ms)');
    title({sprintf('pldapsSyncTests2.m)'), 'Datapixx sync test #1'})
    drawnow;

    %% Measure time to achieve different clock accuracies
    % Set maxduration to 100 ms, thus only relevant for a
    % high precision estimate that might not be reached in that time
    testSettings.maxDuration=0.200;
    
    nsamp = 20;
    nreps = 200;
    % choose steps based on prior test results
    %     steps = logspace(log10(min(durConf(:))), log10(max(durConf(:))), nsamp)*1000; % in ms
    steps = logspace(log10(.02), log10(.3), nsamp);
    
    % pre-allocate
    tstDur = nan(nsamp,nreps);
    
    % testing loop
    fprintf('Testing optMinwinThresholds (est. up to %2.1f min)\n..',testSettings.maxDuration*nsamp*nreps/60)
    tic
    for n=1:nsamp
        
        testSettings.optMinwinThreshold=steps(n)/1000; % in sec
        
        for j=1:nreps
            t0 = GetSecs;
            [~, ~, durConf(n,i)] = syncClocks(testSettings);
            % [getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
            tstDur(n,j) = (GetSecs-t0)*1000;
        end
        if ~mod(n, 10)
            fprintf('.')
        end
    end
    fprintf('Done. (%2.2f min)\n', toc/60)
    
    
    % Plot Minwin test results
    if exist('fig2','var')
        figure(fig2); %#ok<*NODEF>
    else
        fig2 = figure;
    end
    % limits
    xl = [.01, .3];  % steps([1,end]).*[.9,1.1];
    yl = [.03, 1.1*testSettings.maxDuration*1000];
    loglog(steps, median(tstDur,2), '.-', 'color',0*[1 1 1])
    hold on; box off; grid on
    % plot 1sd
    loglog(steps, prctile(tstDur',[16,84]), '-.', 'color',.4*[1 1 1]);
    % plot 95% confidence
    loglog(steps, prctile(tstDur',[2.5,97.5]), ':', 'color',.6*[1 1 1]);
    % simplify ticks
    set(gca, 'LineWidth',0.5,...
        'XTick',[.01,.05,.075,.1,.15,.2,.3,.4,.5],...
        'YTick',[.01,.05,1,2,5,8.3,10,16.7,50,100]);
    xlim(xl); ylim(yl);
    
    xlabel('Requested precision (ms; optMinwinThreshold)');
    ylabel('Time to achieve (ms)');
    title({sprintf('pldapsSyncTests.m'), 'Datapixx sync test #2'})
    drawnow;


% keyboard


%% Test accuracy of chosen setting(s)
% Manually select optimal value for optMinwinThreshold
% and examine how often it might be the limiting factor
figure(fig2);

fprintf(2, '\n\tInput optimal parameters in popup dialogs\n')
   winopts.Resize='on';
   winopts.WindowStyle='normal';
   winopts.Interpreter='none';
% syncmode = str2double(cell2mat(inputdlg('Preferred syncmode (see plot; [r,g,b]==mode[0,1,2]): ', 'syncmode', [1,50], {'1'}, winopts)));
maxDur = str2double(cell2mat(inputdlg('Optimal max duration (ms): ', 'maxDuration', [1,50], {'20'}, winopts)));
minWin = str2double(cell2mat(inputdlg('Minimum precision (ms): ', 'optMinwinThreshold', [1,50], {'0.01'}, winopts)));

% apply settings
syncSettings.maxDuration = maxDur/1000; % in sec
syncSettings.optMinwinThreshold=minWin/1000; % in sec

% collect sample distribution w/ lots of reps
nreps = round(3*60/syncSettings.maxDuration, -2); % run for n minutes
fprintf('Testing params:\n\tmaxDuration = %2.1f ms;\n\toptMinwinThreshold \t= %2.2f ms;\n\t(est. %2.1f min)\n..',...
        syncSettings.maxDuration*1000, syncSettings.optMinwinThreshold*1000, syncSettings.maxDuration*nreps/60);
% pre-allocate
[t,conf] = deal(zeros(1,nreps));

for i=1:nreps
    t0 = GetSecs;
    [~, ~, conf(i)] = syncClocks(syncSettings);
    % [~, ~, conf(i)] = PsychDataPixx('GetPreciseTime');
    t(i)= (GetSecs-t0)*1000;
    
    if ~mod(i, round(nreps/30, -1))
        fprintf('.')
    end
    
end
disp('Done.')


% Plot it
figure,
subplot(1,2,1);
histogram(t, 'normalization','probability');
box off;
xlabel('Time elapsed (ms)');
ylabel('Probability');
title('pldapsSyncTests.m')
% match xlim of histo
drawnow
xl = xlim;

subplot(1,2,2);
% limits
yl = [1, 7]*syncSettings.optMinwinThreshold*1000;  % steps([1,end]).*[.9,1.1];
if syncSettings.optMinwinThreshold ==0, yl = [.02, .25]; end
% scatter plot
loglog(t, conf*1000, '.', 'markersize',4 )
hold on; box off; grid on
% simplify ticks
set(gca, 'LineWidth',0.5);
ylim(yl); set(gca, 'YTick',[.02,.05,.075,.1,.15,.2,.3,.4,.5]);
 xlim(xl); set(gca, 'XTick',[.01,.05,1:5,8.3,10,16.7,20,50,100]);

ylabel('Precision (ms)');
xlabel('Time elapsed (ms)');
title(sprintf('maxDuration = %2.1f ms;  optMinwinThreshold = %2.2f ms;',...
        syncSettings.maxDuration*1000, syncSettings.optMinwinThreshold*1000))

keyboard
end
% %         %% save to your rigPrefs
% %         %this is what I would choose on one setup
% %         ss.datapixx.GetPreciseTime.maxDuration = syncSettings.maxDuration; % time from figure 1 after precision stabilizes
% %         ss.datapixx.GetPreciseTime.optMinwinThreshold = syncSettings.optMinwinThreshold;% choose a threshold sufficient for your needs & duration, i.e. look at figure 2
% % 
% %         %now call createRigPrefs and set your prefrerred values as defaults (or
% %         %don't)
% %         createRigPrefs(ss)
% % 
% %         % end
% %         %% choose a threshold. I'd got for a precision threshold not a time one
% %         % ss.datapixx.GetPreciseTime.syncmode=[]; %1,2,3
% %         % ss.datapixx.GetPreciseTime.maxDuration=[];
% %         % ss.datapixx.GetPreciseTime.optMinwinThreshold=[];
% % 
% %         %this is what Jonas would choose on one setup
% %         ss.datapixx.GetPreciseTime.maxDuration=0.02;%0.01;%or take a time form figure 1 where the result seems very stable, e.g. 0.1s in my case
% %         ss.datapixx.GetPreciseTime.optMinwinThreshold=1.6e-4;%6.5e-5;%choose a threshold that seems relatively sufficient, i.e. look at figure 2
% % 
% %         %now call createRigPrefs and set your prefrerred values as defaults (or
% %         %don't)
% %         createRigPrefs(ss)
% % 
% %         % end


%% Sub-functions
% make this self-contained
% Clock sync routine: Synchronizes host clock (aka GetSecs time) to box
% internal clock via a sampling and calibration procedure:
function [hosttime, boxtime, minwin] = syncClocks(syncSettings)
    
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
    [hosttime, boxtime] = deal(nan);
    
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
        WaitSecs(rand / 1000);
        
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
%     syncresult = [hosttime, boxtime, minwin];
        
    % SyncClocks run finished:
end