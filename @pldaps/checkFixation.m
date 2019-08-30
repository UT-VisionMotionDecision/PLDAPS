function held = checkFixation(p, sn)
% function held = checkFixation(p, sn)
% 
% Default fixation check modular PLDAPS
% Uses pdist to compare pixel coordinates in:
%    [p.trial.eyeX, p.trial.eyeY]
% with
%     p.trial.(sn).fixPosPx &
%     p.trial.(sn).fixLimPx
% 
% Assigns logical fixation held status to:  p.trial.(sn).isheld
% and returns logical [held] variable, if requested
% 
% If no [sn] input, tries to use p.trial.pldaps.modNames.currentFix{1},
% otherwise defaults to 'fix'.
% 
% If p.trial.(sn).mode = 0 will automatically pass through as true
%
% 2018-08-16  TBC  Wrote it.

% assume true to allow code to run w/o any eye tracking setup
held = true;

if p.trial.mouse.useAsEyepos || p.trial.eyelink.useAsEyepos
    if nargin<2
        try
            sn = p.trial.pldaps.modNames.currentFix{1};
        catch
            sn = 'fix';
        end
    end
    
    switch p.trial.(sn).mode
        case 2
            % default to circle window limits as [radius, x/y ratio]
            limRat = p.trial.(sn).fixLimPx(:);
            if numel(limRat)==1
                limRat = [1 1];
            else
                limRat = limRat./limRat(1);
            end
            
            fixXY = p.trial.(sn).fixPosPx(1:2);
            eyeXY = [ (p.trial.eyeX-p.trial.display.ctr(1)), (p.trial.eyeY-p.trial.display.ctr(2)) ]; %p.trial.display.ctr(2)];
            held = all(pdist2( fixXY, eyeXY, 'seuclidean', limRat)...
                   <=  p.trial.(sn).fixLimPx(1));
               %% Updated 'classic' version (...but no speed penalty for pdist use seen in ViewDist rig tests, 08-2018)
               %             held = all(circlewindow(fixXY-eyeXY, p.trial.(sn).fixLimPx));

            %fpXY = p.trial.(sn).fixPosPx(1:2) + p.trial.display.ctr(1:2);
        % % %     %ptype = 'euclidean';
        % % %     held = all(pdist2([p.trial.(sn).fixPosPx(1:2); [p.trial.eyeX p.trial.eyeY]])...
        % % %            <= pdist2([0,0], p.trial.(sn).fixLimPx(1:2)));d

        case 0
            p.trial.(sn).isheld = held;
            return
        otherwise
            % square window  (***this is jank, and not recommended)
            held = squarewindow(0, p.trial.display.ctr(1:2)+p.trial.(sn).fixPosPx-[p.trial.eyeX(1) p.trial.eyeY(1)], p.trial.(sn).fixLimPx(1), p.trial.(sn).fixLimPx(2));
    end
    % Record in pldaps structure before returning
    p.trial.(sn).isheld = held;
end


end
