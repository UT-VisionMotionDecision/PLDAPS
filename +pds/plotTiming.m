function tdat = plotTiming(p)

if nargin<1
    fprintf(2, 'Functionified! %s needs pldaps ''p'' struct or PDS struct input; returns handle to histo. Try:\n\t h = plotTiming(p)\n',mfilename);
    evalin('caller', 'h = plotTiming(p)');
    return
end

%% Extract params from input
% Deal with inconsistencies btwn pldaps obj/structs and PDS structures.
renderTimesToo = isfield(p.data{1},'frameRenderTime');
% inter frame interval
if isprop(p,'trial') || isfield(p, 'trial')
    ifi = p.trial.display.ifi;
elseif isfield(p, 'baseParams')
    % From a saved PDS (w/ modern fields)
    p.trial = p.baseParams;
    ifi = p.trial.display.ifi;
elseif isfield(p, 'initialParametersMerged')
    % From a saved PDS (...outdated fields)
    p.trial = p.initialParametersMerged;
    ifi = p.trial.display.ifi;
else
    % crash probably coming, but try anyway
    ifi = 1/120; % assume 120 hz
end
ifi = ifi*1000; % msec

%% Frame Drop Threshold
dropThresh = 1.1*ifi;


%% Skip over incomplete trials
% % try
% %     goodtr = cellfun(@(x) (isfield(x.pldaps,'goodtrial') && x.pldaps.goodtrial), p.data);
% % catch
    goodtr = true(size(p.data));
% % end
trData = p.data(goodtr);
ntr = numel(trData);

% Limit frame count to most common trial duration
minf = ceil(1.2*median(cellfun(@(x) x.iFrame, trData)));  % min(cellfun(@(x) x.iFrame, trData));   %  

% fliptimes btwn frames (msec)
% ftd = 1000* cell2mat(cellfun(@(x) diff(x.timing.frameStateChangeTimes(1,1:minf))', trData, 'uni',0));
%ftd = 1000* cell2mat(cellfun(@(x) diff(x.timing.flipTimes(1,1:minf))', trData, 'uni',0));

% extract all flipTime diffs, make nan(medFrames, tr), plug values into array == latter diff value [i.e. (2:medFrames)] )
ftd = cellfun(@(x) x.timing.flipTimes(3,:)', trData, 'uni',0);
ftMat = nan(minf, ntr); % matrix nFrames-by-ntrials
for i = 1:ntr
    ii = diff(ftd{i}(1:min(minf,end)));
    ftMat(1:length(ii),i) = 1000 * ii;
end
ftd = ftMat;
    

drops = sum(ftd(:) >= dropThresh);

%% Try additional state info
try
    stateTicks = cell2mat(cellfun(@(x) x.pmBase.statesStartFrame, trData, 'uni',0));
catch
    stateTicks = nan(1, sum(goodtr));
end

%% Plot fliptimes
% Figure layout
spy = 2; spx = 1+renderTimesToo;
cl = ifi*[.75,4.25]; % clim
cm = [.85*[1 1 1]; 0 0 0; 1 1 1; 1 0 0]; % missed frame colormap
pbaspect = [2,1,1];

figure;%(1),clf,
% Plot fliptimes & drops

subplot(spy, spx, 1);           %*** subplot 1 ***
imagesc(ftd');
title( {p.trial.session.file, sprintf('FlipTimes;  %d/%d dropped (%2.3f%%)', drops, numel(ftd), drops/numel(ftd)*100)}, 'interp','none');
xlabel('frame #'), ylabel('trial')
set(gca,'plotboxaspectratio',pbaspect, 'tickdir','out');  box off
colormap(gca, cm); set(gca, 'clim',cl);
cb = colorbar; ylabel(cb, 'msec')


subplot(spy, spx, spx+1)        %*** subplot 3 ***
[~,didx] = find(ftd' >= dropThresh & ~isnan(ftd') );
histogram( didx, floor(minf/10)+1, 'BinLimits',[1,size(ftd,1)], 'Normalization','probability')
title('Dropped frames by time');
xlabel('frame #'), ylabel('prop. total drops')
set(gca,'plotboxaspectratio',pbaspect); box off; grid on;

% Outputs
if nargout>0
    % avoid accidentally dumping all outputs into command window
    tdat.goodtr = goodtr;
    tdat.ftd = ftd;
end


%% Plot frame rendertime (if available)
if renderTimesToo
    % render time/frame (msec)
    %fr = 1000* cell2mat(cellfun(@(x) x.frameRenderTime(1:minf)', trData, 'uni',0));
    fr = cellfun(@(x) x.frameRenderTime', trData, 'uni',0);
        % expand manually with nan blanks
        ftMat = nan(minf, ntr); % matrix nFrames-by-ntrials
        for i = 1:ntr
            ii = fr{i}(1:min(minf,end));
            ftMat(1:length(ii),i) = 1000 * ii;
        end
        fr = ftMat;
    
    
    % Plot render times
    subplot(spy, spx, 2);       %*** subplot 2 ***
    % image plot of frame render times
    imagesc(fr');
    hold on
    % overlay "x" at pmBase behavioral state transitions (i.e. .WAITFIX, .HOLDFIX, .STIMULUS, ...etc)
    plot( stateTicks, repmat(find(goodtr), [size(stateTicks,1),1]), 'gx');
    title('RenderTimes')
    xlabel('frame #'), ylabel('trial')
    set(gca,'plotboxaspectratio',pbaspect, 'clim',prctile(fr(:),[5, 99.9]), 'tickdir','out'); box off
    cb = colorbar; ylabel(cb, 'msec')
    
    subplot(spy, spx, 4);       %*** subplot 4 ***
    %     h = histogram(diff(fr,[],2), 200, 'BinLimits',.5*[-1,1], 'Normalization','probability');
    h = histogram(fr(~isnan(fr)), 200, 'BinLimits',[0.01,ifi], 'Normalization','probability');
    title('frame rendering distribution'); xlabel('msec');
    set(gca,'plotboxaspectratio',pbaspect); box off; grid on;

    % outputs
    if nargout>0
        tdat.fr = fr;
    end
end

