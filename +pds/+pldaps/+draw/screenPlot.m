function screenPlot(sf, x,y, color, linetype, downSample)
        if(length(x)<2)
            return;
        end
        if(nargin<5)
            linetype=sf.linetype; %linetype='-';
        end

        if(nargin<6)
            downSample=false;
        end
        
        if strcmp(linetype, '-')
%             vectorStipple = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
            enableStipple=false;
            dotplot=false;
        elseif(strcmp(linetype, '--'))
%             vectorStipple = [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1];
            enableStipple=true;
            dotplot=false;
        elseif(strcmp(linetype, '.'))
            dotplot=true;
        end
%         [stippleEnabled, stippleFactor, stipleVector]=Screen('LineStipple', sf.window);
%         Screen('LineStipple', sf.window, enableStipple, stippleFactor, vectorStipple);

        %lets do a rough down sampling to the number of pixels the figure
        %actually has
        if downSample && length(x)*4>sf.size(1)
            inds=1:ceil(4*length(x)/sf.size(1)):length(x);
            x=x(inds);
            y=y(inds);
        end
        
        x=reshape(x,1,length(x));
        x=sf.startPos(1) + (x-sf.xlims(1))/(sf.xlims(2)-sf.xlims(1))*sf.size(1);
        y=reshape(y,1,length(y));
        y=sf.startPos(2) - (y-sf.ylims(1))/(sf.ylims(2)-sf.ylims(1))*sf.size(2);
       
        if dotplot
           Screen('Drawdots', sf.window, [x; y], 4, color);   
        else
            if ~enableStipple%we need to double all points except for first and last
                inds=sort([1:length(x) 2:length(x)-1]);
                x=x(inds);
                y=y(inds);
            end

            Screen('DrawLines', sf.window, [x; y], 4, color);
        end

%         Screen('LineStipple', sf.window, stippleEnabled, stippleFactor, stipleVector);
end