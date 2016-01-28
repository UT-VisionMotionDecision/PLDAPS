%pldapsSyncTests   a script with commands to test the best datapixx timing options
%                  for your system
% By default PsychDatapixx estimates the time delay between the computer
% and datapixx for 0.5 seconds. On many systems there is no benefit of soing this for such a long time.
% this script is menat to help find good parameters
% for three parameters are syncmode,optMinwinThreshold and maxDuration. I
% will always use syncmode 2, default is 1 I think. check edit
% PsychDatapixx and search for GetPreciseTime for details

%%test datapixx timing
PsychDataPixx('open');
global dpx;
dpx.syncmode=2; %1,2,3


%% first test how much better your delay estimate get's when you increase the measurement time
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
savefig(gcf,'PDMinDurationTest')

%% next how long it takes to typically reach the observed values. 
% We set a maxduration to some value. This is only relevant for for the
% high precision estimate, that might not get reached in that time
dpx.maxDuration=0.1;
t=zeros(41,100);

steps=min(p):(max(p)-min(p))/40:max(p);

for n=1:21

dpx.optMinwinThreshold=steps(n);

    for j=1:100
        tic;[getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');t(n,j)=toc*1000;
    end
end

figure(2)
plot(steps,mean(t,2))
hold on;
plot(steps,mean(t,2)+std(t,0,2),'--');
ylabel('time / s');
xlabel('precision / s');
savefig(gcf,'PDOptMinThresholdTest')
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
a.datapixx.GetPreciseTime.syncmode=[]; %1,2,3
a.datapixx.GetPreciseTime.maxDuration=[];
a.datapixx.GetPreciseTime.optMinwinThreshold=[];

%this is what I would choose on one setup
a.datapixx.GetPreciseTime.syncmode=2; %1,2,3
a.datapixx.GetPreciseTime.maxDuration=0.02;%0.01;%or take a time form figure 1 where the result seems very stable, e.g. 0.1s in my case
a.datapixx.GetPreciseTime.optMinwinThreshold=1.6e-4;%6.5e-5;%choose a threshold that seems relatively sufficient, i.e. look at figure 2

%now call createRigPrefs and set your prefrerred values as defaults (or
%don't)
createRigPrefs(a)

% doesnt help much. eyelink time estimate is always inacrurate, very variable (roughly +- 0.6 ms) due to
% the way sr research handles timing. 
% %% now do the same for eyelink
% Eyelink('Initialize');
% p=zeros(500,1);
% 
% optMinwinThreshold=0;
% for n=1:500
% 
%     maxDuration=n/1000;
% 
%     [~, ~, p(n,1)] = pds.eyelink.getPreciseTime(optMinwinThreshold,maxDuration);
% end
% 
% figure(1)
% plot((1:500)/1000,p)
% xlabel('time / s');
% ylabel('precision / s');
% drawnow;
% 
% maxDuration=0.5;
% t=zeros(21,100);
% 
% steps=min(p):(max(p)-min(p))/20:max(p);
% 
% for n=1:21
% 
% optMinwinThreshold=steps(n);%(5+0.1*(n-1))*1e-5;
% 
%     for j=1:100
%         tic;[getsecs, boxsecs, confidence] = pds.eyelink.getPreciseTime(optMinwinThreshold,maxDuration);t(n,j)=toc*1000;
%     end
% end
% 
% % hist(t',0:100)
% figure(2)
% plot(steps,mean(t,2))
% hold on;
% plot(steps,mean(t,2)+std(t,0,2),'--');
% ylabel('time / s');
% xlabel('precision / s');

