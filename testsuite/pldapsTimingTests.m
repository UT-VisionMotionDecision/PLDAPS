%very rough firt draft, need something pretty and well documented
%% datapixx
dptime=cellfun(@(x) x.timing.datapixxPreciseTime, PDS.data, 'UniformOutput', false);
dptime=vertcat(dptime{:})';
dpfit2=polyfit(dptime(2,:),dptime(1,:),1);
dp2c=@(x) x*dpfit2(1) + dpfit2(2);

% [dpfit dpfitS dpfitMU]=polyfit(dptime(2,:),dptime(1,:),1)
% g=dpfit(1)/dpfitMU(2);
% h;

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

% for idmaxframes=1:length(nrframes)

% idmaxframes=84
thisdata=PDS.data{idmaxframes};

tdELTime=el2c(thisdata.eyelink.samples(1,:)/1000);
tdELData=thisdata.eyelink.samples(5,:);


tdDPTime=dp2c(thisdata.datapixx.adc.dataSampleTimes);
tdDPData=thisdata.datapixx.adc.data(1,:);


try
% minidx=1;
% idx=tdELData*0+1;
% [~,idx(1)]=min(abs(tdDPTime(1:end)-tdELTime(1)));
% for j=2:length(tdELTime)
%    [~,id]=min(abs(tdDPTime(idx(j-1):end)-tdELTime(j)));
%    idx(j)=id+idx(j-1)-1;
% end
minidx=1;
idx=tdELData*0+1;
[~,idx(1)]=min(abs(tdDPTime(1:end)-tdELTime(1)));
[~,idx(2)]=min(abs(tdDPTime(1:end)-tdELTime(2)));
est_diff_rate=idx(2)-idx(1);
nSamplesEL=length(tdELTime);
nSamplesDP=length(tdDPTime);
for j=3:nSamplesEL
   newidx=min(idx(j-1)+est_diff_rate,nSamplesDP);
   mindiff=min(abs(tdDPTime(newidx)-tdELTime(j)));
   
   if newidx<nSamplesDP
       mindiff2=min(abs(tdDPTime(newidx+1)-tdELTime(j)));
       while mindiff2 < mindiff
           newidx=newidx+1;
           mindiff=mindiff2;
           if newidx<nSamplesDP
            mindiff2=min(abs(tdDPTime(newidx+1)-tdELTime(j)));
           else
               break
           end
       end
   end
   
   mindiff2=min(abs(tdDPTime(newidx-1)-tdELTime(j)));
   while mindiff2 < mindiff
       newidx=newidx-1;
       mindiff=mindiff2;
       mindiff2=min(abs(tdDPTime(newidx-1)-tdELTime(j)));
   end
       
   idx(j)=newidx;
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

%%other way araound
minidx=1;
idx=tdDPData*0+1;
[~,idx(1)]=min(abs(tdELTime(1:end)-tdDPTime(1)));
[~,idx(2)]=min(abs(tdELTime(1:end)-tdDPTime(2)));
est_diff_rate=idx(2)-idx(1);
nSamplesEL=length(tdELTime);
nSamplesDP=length(tdDPTime);
for j=3:nSamplesDP
   newidx=min(idx(j-1)+est_diff_rate,nSamplesEL);
   mindiff=min(abs(tdELTime(newidx)-tdDPTime(j)));
   
   if newidx<nSamplesEL
       mindiff2=min(abs(tdELTime(newidx+1)-tdDPTime(j)));
       while mindiff2 < mindiff
           newidx=newidx+1;
           mindiff=mindiff2;
           if newidx<nSamplesEL
            mindiff2=min(abs(tdELTime(newidx+1)-tdDPTime(j)));
           else
               break
           end
       end
   end
   
   if newidx>1
       mindiff2=min(abs(tdELTime(newidx-1)-tdDPTime(j)));
       while mindiff2 < mindiff
           newidx=newidx-1;
           mindiff=mindiff2;
           mindiff2=min(abs(tdELTime(newidx-1)-tdDPTime(j)));
       end
   end
       
   idx(j)=newidx;
end
elDownSapleTime=tdELTime(idx);
elDownSapleData=tdELData(idx); 
   
maxlag=1000;
[x,l]=xcorr(tdDPData,elDownSapleData,maxlag);
figure;
plot(l,x)
xlabel('Lag in Datapixx Samples');
ylabel('x-correlation');

lag=l(x==max(x));
estimated_el_DP_lag=tdDPTime(abs(lag)+1)-tdDPTime(1);

fprintf('estimated lag between Eyelink and Datapixx is %i ms\n', sign(lag)*round(estimated_el_DP_lag*1000));
if lag>0
    fprintf('Datapixx data is behind of Eyelink data\n');
else
    fprintf('Datapixx data is ahead of Eyelink data\n');
end

allags(idmaxframes)=lag;
catch
    allags(idmaxframes)=NaN;
end

% end
% 
% minidx=1;
% idx=tdELData*0+1;
% [~,idx(1)]=min(abs(tdDPTime(1:end)-tdELTime(1)+lag/1000));
% [~,idx(2)]=min(abs(tdDPTime(1:end)-tdELTime(2)+lag/1000));
% for j=2:length(tdELTime)
%    [~,id]=min(abs(tdDPTime(idx(j-1):end)-tdELTime(j)+lag/1000));
%    idx(j)=id+idx(j-1)-1;
% end
% dpDownSapleTime=tdDPTime(idx)+lag/1000;
% dpDownSapleData=tdDPData(idx); 
%    
lagseconds=median(diff(tdELTime))*lag;
minidx=1;
idx=tdELData*0+1;
[~,idx(1)]=min(abs(tdDPTime(1:end)-tdELTime(1)+lagseconds));
[~,idx(2)]=min(abs(tdDPTime(1:end)-tdELTime(2)+lagseconds));
est_diff_rate=idx(2)-idx(1);
nSamplesEL=length(tdELTime);
nSamplesDP=length(tdDPTime);
for j=3:nSamplesEL
   newidx=min(idx(j-1)+est_diff_rate,nSamplesDP);
   mindiff=min(abs(tdDPTime(newidx)-tdELTime(j)+lagseconds));
   
   if newidx<nSamplesDP
       mindiff2=min(abs(tdDPTime(newidx+1)-tdELTime(j)+lagseconds));
       while mindiff2 < mindiff
           newidx=newidx+1;
           mindiff=mindiff2;
           if newidx<nSamplesDP
            mindiff2=min(abs(tdDPTime(newidx+1)-tdELTime(j)+lagseconds));
           else
               break;
           end
               
       end
   end
   
   mindiff2=min(abs(tdDPTime(newidx-1)-tdELTime(j)+lagseconds));
   while mindiff2 < mindiff
       newidx=newidx-1;
       mindiff=mindiff2;
       mindiff2=min(abs(tdDPTime(newidx-1)-tdELTime(j)+lagseconds));
   end
       
   idx(j)=newidx;
end
dpDownSapleTime=tdDPTime(idx)+lagseconds;
dpDownSapleData=tdDPData(idx); 
   


n=tdELData>-3000;

scaling=polyfit(dpDownSapleData(n),tdELData(n),1)
figure;
plot(tdELTime,tdELData);
hold on;
plot(dpDownSapleTime,scaling(1)*dpDownSapleData+scaling(2),'g')



