%very rough firt draft, need something pretty and well documented
%% datapixx
dptime=cellfun(@(x) x.timing.datapixxPreciseTime, PDS.data, 'UniformOutput', false);
dptime=vertcat(dptime{:})';
dpfit=polyfit(dptime(2,:),dptime(1,:),1);
dp2c=@(x) x*dpfit(1) + dpfit(2);

figure;
plot(dptime(1,:), 1000*( dp2c(dptime(2,:)) - dptime(1,:)) )
xlabel('Datapixx time / s')
ylabel('Datapixx time reconstruction error / ms')

%% eyelink
eltime=cellfun(@(x) x.timing.eyelinkStartTime, PDS.data, 'UniformOutput', false);
eltime=vertcat(eltime{:})';
elfit=polyfit(eltime(2,:),eltime(1,:),1);
el2c=@(x) x*elfit(1) + elfit(2);
figure;
plot(eltime(1,:), 1000*( el2c(eltime(2,:)) - eltime(1,:)) )
xlabel('Eyelink time / s')
ylabel('Eyelink time reconstruction error / ms')

nrframes=cellfun(@(x) size(x.timing.frameStateChangeTimes,2), PDS.data);
idmaxframes=find(nrframes==max(nrframes));

% idmaxframes=84
thisdata=PDS.data{idmaxframes};

tdELTime=el2c(thisdata.eyelink.samples(1,:)/1000);
tdELData=thisdata.eyelink.samples(5,:);


tdDPTime=dp2c(thisdata.datapixx.adc.dataSampleTimes);
tdDPData=thisdata.datapixx.adc.data(1,:);


% elq=quantile(tdELData, [.25 .50 .75]);
% dpq=quantile(tdDPData, [.25 .50 .75]);
% dpelf=(elq(2)-elq(1))/(dpq(2)-dpq(1));
% dpqf=quantile(tdDPData*dpelf, [.25 .50 .75]);
% dpelo=-dpqf(2)+elq(2);
% 
% plot(tdDPTime,tdDPData*dpelf + dpelo)
% hold on;
% plot(tdELTime,tdELData,'g')
% plot(tdELTime+4/1000,tdELData,'m')

%dp data is ->4ms delayed. why?

%slow
% dpDownSapleTime=tdELTime;
% dpDownSapleData=tdELData;
minidx=1;
idx=tdELData*0+1;
[~,idx(1)]=min(abs(tdDPTime(1:end)-tdELTime(1)));
for j=2:length(tdELTime)
   [~,id]=min(abs(tdDPTime(idx(j-1):end)-tdELTime(j)));
   idx(j)=id+idx(j-1)-1;
end
dpDownSapleTime=tdDPTime(idx);
dpDownSapleData=tdDPData(idx); 
   
maxlag=1000;
[x,l]=xcorr(tdELData,dpDownSapleData,maxlag);
figure;
plot(l,x)
xlabel('Lag in Eyelink Samples');
ylabel('x-correlation');

lag=l(x==max(x));
estimated_dp_el_lag=tdELTime(abs(lag)+1)-tdELTime(1);

fprintf('estimated lag between Datapixx and Eyelink is %i ms\n', sign(lag)*round(estimated_dp_el_lag*1000));
if lag>0
    fprintf('Datapixx data is ahead of Eyelink data\n');
else
    fprintf('Datapixx data is behind of Eyelink data\n');
end


%alternative: use all data
tdELTime=cellfun(@(x) x.eyelink.samples(1,:)/1000, PDS.data, 'UniformOutput',false);
tdELTime=el2c(horzcat(tdELTime{:}));

tdELData=cellfun(@(x) x.eyelink.samples(5,:), PDS.data, 'UniformOutput',false);
tdELData=horzcat(tdELData{:});

tdDPTime=cellfun(@(x) x.datapixx.adc.dataSampleTimes, PDS.data, 'UniformOutput',false);
tdDPTime=dp2c(horzcat(tdDPTime{:}));

tdDPData=cellfun(@(x) x.datapixx.adc.data(1,:), PDS.data, 'UniformOutput',false);
tdDPData=horzcat(tdDPData{:});
