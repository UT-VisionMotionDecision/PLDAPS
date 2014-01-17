function [xy] = sampleTargetLocation(rect, gridx)

if nargin < 2
    gridx = [];
    if nargin < 1
        
        rect = [-300 -300 300 300];
    end
end



if isempty(gridx)
    x = rect(1) + (rect(3)-rect(1))*rand;
    y = rect(2) + (rect(4)-rect(2))*rand;
else
    xi = round(unifrnd(1,gridx));
    yi = round(unifrnd(1,gridx));
    
    xlocs = round(linspace(rect(1),rect(3), gridx));
    ylocs = round(linspace(rect(2),rect(4), gridx));
    
    
    
    
    x = xlocs(xi);
    y = ylocs(yi);
    
end

maxIter = 50;
iter = 1;

while sqrt(x^2 + y^2) < 150 && iter < maxIter
    
    if isempty(gridx)
        x = rect(1) + (rect(3)-rect(1))*rand;
        y = rect(2) + (rect(4)-rect(2))*rand;
    else
        xi = round(unifrnd(1,gridx));
        yi = round(unifrnd(1,gridx));
        
        x = xlocs(xi);
        y = ylocs(yi);
    end
    
    iter = iter+1;
end



xy = [x -y];