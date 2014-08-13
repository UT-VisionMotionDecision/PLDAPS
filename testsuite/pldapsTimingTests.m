%very rough firt draft, need something pretty and well documented
%% datapixx
dptime=cellfun(@(x) x.timing.datapixxPreciseTime, PDS.data, 'UniformOutput', false);
dptime=vertcat(dptime{:})';
dpfit=polyfit(dptime(2,:),dptime(1,:),1);
dp2c=@(x) x*dpfit(1) + dpfit(2);

plot(dptime(1,:), 1000*( dp2c(dptime(2,:)) - dptime(1,:)) )

%% eyelink
eltime=cellfun(@(x) x.timing.eyelinkStartTime, PDS.data, 'UniformOutput', false);
eltime=vertcat(eltime{:})';
elfit=polyfit(eltime(2,:),eltime(1,:),1);
el2c=@(x) x*elfit(1) + elfit(2);
plot(eltime(1,:), 1000*( el2c(eltime(2,:)) - eltime(1,:)) )

nrframes=cellfun(@(x) size(x.timing.frameStateChangeTimes,2), PDS.data);
idmaxframes=find(nrframes==max(nrframes));

% idmaxframes=84
thisdata=PDS.data{idmaxframes};

tdELTime=el2c(thisdata.eyelink.samples(1,:)/1000);
tdELData=thisdata.eyelink.samples(5,:);


tdDPTime=dp2c(thisdata.datapixx.adc.dataSampleTimes);
tdDPData=thisdata.datapixx.adc.data(1,:);


elq=quantile(tdELData, [.25 .50 .75]);
dpq=quantile(tdDPData, [.25 .50 .75]);
dpelf=(elq(2)-elq(1))/(dpq(2)-dpq(1));
dpqf=quantile(tdDPData*dpelf, [.25 .50 .75]);
dpelo=-dpqf(2)+elq(2);

plot(tdDPTime,tdDPData*dpelf + dpelo)
hold on;
plot(tdELTime,tdELData,'g')
plot(tdELTime+4/1000,tdELData,'m')

%dp data is ->4ms delayed. why?