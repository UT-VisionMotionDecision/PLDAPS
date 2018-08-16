% script ShuffleMexDemo.m
%  Create demo figure showing effect of ShuffleMex across various dimensions
%  
%  2018-08-16  TBC  Wrote it.

% sample matrix
sz = [10,4,3];
x = nan(sz); 
x(:) = 0:numel(x)-1;

%% Plot various shuffles
h = figure;
set(h, 'name', 'ShuffleMexDemo','NumberTitle','off')
colormap(hsv)
nsp = length(sz)+1;

subplot(nsp,1,1)
imagesc(reshape(x, [sz(1),prod(sz(2:end))]));
ylabel('No shuffle')
box off;

for i = 1:nsp-1
    subplot(nsp,1,i+1)
    imagesc(reshape(ShuffleMex(x,i), [sz(1),prod(sz(2:end))]));
    ylabel(sprintf('Shuffle Dim%d',i))
    box off;
end