nTrials = 100;
nModules = 10; % number of stimulus modules that will have some random number generation
nFrames = 1e3;
fname = 'testseeds.mat';

% build trial seeds for each stimulus module
module = cell(nModules,1);
for i = 1:nModules
    module{i}.trialSeeds = randseed(i, nTrials);
end

% --- run a sample experiment
data = cell(nTrials,1);
for kTrial = 1:nTrials
    
    % --- set trial seeds
    for i = 1:nModules
        data{kTrial}.module{i}.stream = RandStream('mt19937ar', 'Seed', module{i}.trialSeeds(kTrial));
        data{kTrial}.module{i}.val = nan(nFrames, 1);
    end
    
    % --- loop over frames for each trial
    data{kTrial}.tdur = nan(nFrames, 1);
    for j = 1:nFrames
        tic
        for i = 1:nModules
            data{kTrial}.module{i}.val(j) = rand(data{kTrial}.module{i}.stream);
        end
        data{kTrial}.tdur(j) = toc;
    end
    
end
disp('Done generating random data')
disp('saving temporary file')

% save out the data
save(fname, 'data')

% re-load the data and see if the seeds can be perfectly reconstructed
B = load(fname);

valReconstruct = cell(nModules, 1);
valOriginal = cell(nModules, 1);

for i = 1:nModules
reconstructed = cell(nModules,1);
for kTrial = 1:numel(B.data)
    B.data{kTrial}.module{i}.stream.reset;
    reconstructed{kTrial}.val = nan(nFrames,1);
    for j = 1:nFrames
        reconstructed{kTrial}.val(j) = rand(B.data{kTrial}.module{i}.stream);
    end
end

valReconstruct{i} = cell2mat(cellfun(@(x) x.val(:)', reconstructed(:)', 'UniformOutput', false));
valOriginal{i}    = cell2mat(cellfun(@(x) x.module{i}.val(:)', data(:)', 'UniformOutput', false));

assert(all(valReconstruct{i}==valOriginal{i}), 'Reconstructed seeds do not match')
fprintf('module %d perfectly reconstructed\n', i)
end


% --- check for correlations in the generated random numbers
[rho, pval] = corr(cell2mat(valReconstruct)');
ix = ~triu(ones(nModules)); % index into correlation matrix
fprintf('Correlation coefficients for the random variables for the %d modules are:\n', nModules)
fprintf('%0.4f, ', rho(ix))
fprintf('\n')
if ~any(pval(ix)<.05)
    fprintf('none are significantly correlated\n')
else
    warning('some random numbers were significantly correlated')
end

figure(1); clf
subplot(1,2,1)
imagesc(rho)
title('correlation matrix')
subplot(1,2,2)
imagesc(rho.*~eye(nModules))
colorbar
title('(diagonal removed)')

delete(fname)
