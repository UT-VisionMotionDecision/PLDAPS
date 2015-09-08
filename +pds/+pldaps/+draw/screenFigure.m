%% create a new screen figure (i.e. a struct with parameters used by screenPlot)
    function sf = screenFigure(p, startPos, size, windowPointer, xlims,ylims,fontSize,axisColor)
        %ok, let's not fiddle with pixels, use cm
        % this will hold all essential information used to scale the data
        sf.startPos=round(startPos.*[p.trial.display.pWidth/p.trial.display.wWidth p.trial.display.pHeight/p.trial.display.wHeight] + [p.trial.display.pWidth/2 p.trial.display.pHeight/2]);
        sf.size=ceil(size.*[p.trial.display.pWidth/p.trial.display.wWidth p.trial.display.pHeight/p.trial.display.wHeight]);
        sf.window=windowPointer;
        sf.xlims = xlims;
        sf.ylims=  ylims;
        sf.linetype='-';
% drawing axes was too slow, disabled for now
%         sf.fontSize=fontSize;
%         sf.tickLength=fontSize/2;
%         sf.tickNum=5;
%         sf.axisColor = axisColor;        
    end    