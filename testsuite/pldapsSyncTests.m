
%%test datapixx timing
PsychDataPixx('open');
global dpx;
dpx.syncmode=2; %1,2,3

p=zeros(500,1);

dpx.optMinwinThreshold=0;
for n=1:500

    dpx.maxDuration=n/1000;

    [~, ~, p(n,1)] = PsychDataPixx('GetPreciseTime');
end

figure(1)
plot((1:500)/1000,p)
xlabel('time / s');
ylabel('precision / s');
drawnow;

dpx.maxDuration=0.1;
t=zeros(41,100);

steps=min(p):(max(p)-min(p))/40:max(p);

for n=1:21

dpx.optMinwinThreshold=steps(n);%(5+0.1*(n-1))*1e-5;

    for j=1:100
        tic;[getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');t(n,j)=toc*1000;
    end
end

% hist(t',0:100)
figure(2)
plot(steps,mean(t,2))
hold on;
plot(steps,mean(t,2)+std(t,0,2),'--');
ylabel('time / s');
xlabel('precision / s');

keyboard;

    t=zeros(1,1000);
    for j=1:1000
        tic;[getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');t(j)=toc*1000;
    end
    
    hist(t)
    
%%choose a threshold. I'd got for a precision threshold not a time one, but
%%it probbbaly dosn't matter.

%syncmode 1: It uses the time the datapixx functions returns as estimate of
%the comuter time. this is the default
%syncmode 0: Same but used the time the datapixx function is entered
%syncmode 2: Uses the average of 1 and 3
a.datapixx.syncing.syncmode=[]; %1,2,3
a.datapixx.syncing.maxDuration=[];
a.datapixx.syncing.optMinwinThreshold=[];

%other rig: 500ms and 1.5e-4

%this is what I would choose
a.datapixx.syncing.syncmode=2; %1,2,3
a.datapixx.syncing.maxDuration=0.01;%or take a time form figure 1 where the result seems very stable, e.g. 0.1s in my case
a.datapixx.syncing.optMinwinThreshold=6.5e-5;%choose a threshold that seems relatively sufficient, i.e. look at figure 2
%on my test rig 5e-5 takes 500ns, 5.5e-5 90ms, 6e-5 7.5ms, 6.5e-5 7ms, 7e-6
%3.6ms
%I'd choose 6 as it's suffitiently short and robust, yet close the the
%maximum possible precision which is at aorunt 5ms
%You are looking for the sweet spot that gives the best precision for the
%time invested. 

%both reults in about 7ms time. to maybe a fixed time of 10ms would to
%similarly well

%% now do the same for eyelink
Eyelink('Initialize');
p=zeros(500,1);

optMinwinThreshold=0;
for n=1:500

    maxDuration=n/1000;

    [~, ~, p(n,1)] = pds.eyelink.getPreciseTime(optMinwinThreshold,maxDuration);
end

figure(1)
plot((1:500)/1000,p)
xlabel('time / s');
ylabel('precision / s');
drawnow;

maxDuration=0.5;
t=zeros(21,100);

steps=min(p):(max(p)-min(p))/20:max(p);

for n=1:21

optMinwinThreshold=steps(n);%(5+0.1*(n-1))*1e-5;

    for j=1:100
        tic;[getsecs, boxsecs, confidence] = pds.eyelink.getPreciseTime(optMinwinThreshold,maxDuration);t(n,j)=toc*1000;
    end
end

% hist(t',0:100)
figure(2)
plot(steps,mean(t,2))
hold on;
plot(steps,mean(t,2)+std(t,0,2),'--');
ylabel('time / s');
xlabel('precision / s');

%other rig: 100ms, 6e-5 when using request time
%           100ms, 2.5e-5  (avg 12ms) when using TrackerTime
%                   or 5.5e-5 (avg 3ms)

