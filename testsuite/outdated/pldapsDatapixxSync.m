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

% defaults
cols = 'rgb';

% Prepare for test 
PsychDataPixx('open');
% ...direct Datapixx('open') call doesn't create necessary [dpx] var
global dpx;

for smode = [0,1,2]
    dpx.syncmode = smode; % (==0,1,or 2; default==1)
    fprintf(2, [fprintLineBreak, 'syncmode %d\n'], smode);
    
    %% Optimize max duration of samples
    % zero out optimal threshold to ensure maxDuration is the limiting factor for this test
    dpx.optMinwinThreshold=0;
    
    % setup sample points
    nsamp = 200;
    nreps = 10;
    %         durLims = [1, nsamp];
    %         durs = linspace(durLims(1), durLims(2), nsamp);
    durLims = [2, 500]; % ms
    durs = logspace(log10(durLims(1)), log10(durLims(2)), nsamp);
    
    % pre-allocate
    durConf = nan(nsamp,1);
    
    % testing loop
    fprintf('Testing maxDurations (est. %2.1f min)\n..',sum(durs.*nreps)/1000/60);
    tic
    for n = 1:nsamp
        
        dpx.maxDuration=durs(n)/1000; % in sec
        %   [~, ~, durConf(n,1)] = PsychDataPixx('GetPreciseTime');
        for i = 1:nreps
            [~, ~, durConf(n,i)] = PsychDataPixx('GetPreciseTime');
            %   [~, ~, jnk(i)] = PsychDataPixx('GetPreciseTime'); %#ok<SAGROW>
        end
        
        if ~mod(n, 50)
            fprintf('.')
        end
    end
    fprintf('Done. (%2.2f min)\n', toc/60)
    % Plot the 90th prctile for a high baseline estimate of possible timing precision
    durConfMed = prctile(durConf',90);
    
    % Plot dur test results
    if exist('fig1','var') && dpx.syncmode~=0
        figure(fig1);
    else
        fig1 = figure;
    end
    semilogx(durs, durConfMed*1000, 'color',cols(dpx.syncmode+1));
    hold on, box off, grid on
    set(gca, 'LineWidth',0.5,...
        'XTick',[1,2,5,10,20,50,100,200,300,400,500]);
    xlim(durs([1,end]).*[.9,1.1]);
    ylim([.045, .45])
    xlabel('Sync duration (ms; maxDuration)');
    ylabel('Resulting precision (ms)');
    title({sprintf('pldapsSyncTests.m,   dpx.syncmode= %d',dpx.syncmode), 'Datapixx sync test #1'})
    drawnow;
    
    %% Measure time to achieve different clock accuracies
    % Set maxduration to 100 ms, thus only relevant for a
    % high precision estimate that might not be reached in that time
    dpx.maxDuration=0.1;
    
    nsamp = 20;
    nreps = 200;
    % choose steps based on prior test results
    %     steps = logspace(log10(min(durConf(:))), log10(max(durConf(:))), nsamp)*1000; % in ms
    steps = logspace(log10(.075), log10(.3), nsamp);
    
    % pre-allocate
    tstDur = nan(nsamp,nreps);
    
    % testing loop
    fprintf('Testing optMinwinThresholds (est. %2.1f min)\n..',dpx.maxDuration*nsamp*nreps/60)
    tic
    for n=1:nsamp
        
        dpx.optMinwinThreshold=steps(n)/1000; % in sec
        
        for j=1:nreps
            t0 = GetSecs;
            [getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
            tstDur(n,j) = (GetSecs-t0)*1000;
        end
        if ~mod(n, 10)
            fprintf('.')
        end
    end
    fprintf('Done. (%2.2f min)\n', toc/60)
    
    
    % Plot Minwin test results
    if exist('fig2','var') && dpx.syncmode~=0
        figure(fig2);
    else
        fig2 = figure;
    end
    % limits
    xl = [.07, .3];  % steps([1,end]).*[.9,1.1];
    yl = [1, 1.1*dpx.maxDuration*1000];
    loglog(steps, median(tstDur,2), '.-', 'color',cols(dpx.syncmode+1))
    hold on; box off; grid on
    % plot 1sd
    loglog(steps, prctile(tstDur',[16,84]), '-.', 'color',cols(dpx.syncmode+1));
    % plot 95% confidence
    loglog(steps, prctile(tstDur',[2.5,97.5]), ':', 'color',cols(dpx.syncmode+1));
    % simplify ticks
    set(gca, 'LineWidth',0.5,...
        'XTick',[.05,.075,.1,.15,.2,.3,.4,.5],...
        'YTick',[1,2,5,8.3,10,16.7,50,100]);
    xlim(xl); ylim(yl);
    
    xlabel('Requested precision (ms; optMinwinThreshold)');
    ylabel('Time to achieve (ms)');
    title({sprintf('pldapsSyncTests.m,   dpx.syncmode= %d',dpx.syncmode), 'Datapixx sync test #2'})
    drawnow;
end

figure(fig1)
legend({'syncmode(0)','syncmode(1)','syncmode(2)'});

%% Test accuracy of chosen setting(s)
% Manually select optimal value for optMinwinThreshold
% and examine how often it might be the limiting factor
figure(fig2);

fprintf(2, '\n\tInput optimal parameters in popup dialogs\n')
   winopts.Resize='on';
   winopts.WindowStyle='normal';
   winopts.Interpreter='none';
syncmode = str2double(cell2mat(inputdlg('Preferred syncmode (see plot; [r,g,b]==mode[0,1,2]): ', 'syncmode', [1,50], {'1'}, winopts)));
maxDur = str2double(cell2mat(inputdlg('Optimal max duration (ms): ', 'maxDuration', [1,50], {'30'}, winopts)));
minWin = str2double(cell2mat(inputdlg('Minimum precision (ms): ', 'optMinwinThreshold', [1,50], {'0.0'}, winopts)));

% apply settings
dpx.syncmode = syncmode;
dpx.maxDuration = maxDur/1000; % in sec
dpx.optMinwinThreshold=minWin/1000; % in sec

% collect sample distribution w/ lots of reps
nreps = round(3*60/dpx.maxDuration, -2); % run for n minutes
fprintf('Testing params:\n\tsyncmode = %d;\tmaxDuration = %2.1f ms;\n\toptMinwinThreshold \t= %2.2f ms;\n\t(est. %2.1f min)\n..',...
        dpx.syncmode, dpx.maxDuration*1000, dpx.optMinwinThreshold*1000, dpx.maxDuration*nreps/60);
% pre-allocate
[t,conf] = deal(zeros(1,nreps));

for i=1:nreps
    t0 = GetSecs;
    [~, ~, conf(i)] = PsychDataPixx('GetPreciseTime');
    t(i)= (GetSecs-t0)*1000;
    
    if ~mod(i, round(nreps/30, -1))
        fprintf('.')
    end
    
end
disp('Done.')


% Plot it
figure,
subplot(1,2,1);
hh = histogram(t, 'normalization','probability');
box off;
xlabel('Time elapsed (ms)');
ylabel('Probability');
title('pldapsSyncTests.m')
% match xlim of histo
xl = xlim;

subplot(1,2,2);
% limits
yl = [.1, 1.1]*dpx.optMinwinThreshold*1000;  % steps([1,end]).*[.9,1.1];
if dpx.optMinwinThreshold ==0, yl = [.05, .25]; end
% scatter plot
loglog(t, conf*1000, '.', 'markersize',4 )
hold on; box off; grid on
% simplify ticks
set(gca, 'LineWidth',0.5);
ylim(yl); set(gca, 'YTick',[.05,.075,.1,.15,.2,.3,.4,.5]);
 xlim(xl); set(gca, 'XTick',[1,2,5,8.3,10,16.7,50,100]);

ylabel('Precision (ms)');
xlabel('Time elapsed (ms)');
title(sprintf('syncmode = %d;  maxDuration = %2.1f ms;  optMinwinThreshold = %2.2f ms;',...
        dpx.syncmode, dpx.maxDuration*1000, dpx.optMinwinThreshold*1000))

return

%% save to your rigPrefs
%this is what I would choose on one setup
ss.datapixx.GetPreciseTime.syncmode = syncmode; %1,2,3
ss.datapixx.GetPreciseTime.maxDuration = maxDur/1000; % time from figure 1 after precision stabilizes
ss.datapixx.GetPreciseTime.optMinwinThreshold = minWin;% choose a threshold sufficient for your needs & duration, i.e. look at figure 2

%now call createRigPrefs and set your prefrerred values as defaults (or
%don't)
createRigPrefs(ss)


%% choose a threshold. I'd got for a precision threshold not a time one, but
%%it probbbaly dosn't matter.

%syncmode 1: It uses the time the datapixx functions returns as estimate of
%the comuter time. this is the default
%syncmode 0: Same but used the time the datapixx function is entered
%syncmode 2: Uses the average of 1 and 3
ss.datapixx.GetPreciseTime.syncmode=[]; %1,2,3
ss.datapixx.GetPreciseTime.maxDuration=[];
ss.datapixx.GetPreciseTime.optMinwinThreshold=[];

%this is what I would choose on one setup
ss.datapixx.GetPreciseTime.syncmode=2; %1,2,3
ss.datapixx.GetPreciseTime.maxDuration=0.02;%0.01;%or take a time form figure 1 where the result seems very stable, e.g. 0.1s in my case
ss.datapixx.GetPreciseTime.optMinwinThreshold=1.6e-4;%6.5e-5;%choose a threshold that seems relatively sufficient, i.e. look at figure 2

%now call createRigPrefs and set your prefrerred values as defaults (or
%don't)
createRigPrefs(ss)

