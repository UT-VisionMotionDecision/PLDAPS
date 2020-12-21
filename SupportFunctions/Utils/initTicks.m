function p = initTicks(p)
% p = initTicks(p)
% Initialize grid of tick marks for Screen('DrawLines')
% initTicks creates a matrix for drawing tick marks on the human display 
% spaced every degree of visual angle. This grids up the screen into 1deg and
% 5deg step sizes so the experimenter can easily see the eccentricity of the
% stimulus. Set p.trial.pldaps.draw.grid.use=true if you want ticks on your
% display. 
% 
% INPUTS:
%   p [class]
%     .trial [struct] - main variables structure (see PLDAPShelp)
%       .display   - display structure 
%           .width screen width in degree
%           .height screen height in degree
% OUTPUTS:
%   p [class]
%     .trial [struct] - main variables structure (modified)
%       .display   - display stucture  (modified)
%         .draw
%           .grid
%             .tick_line_matrix - field added in format called by
%                               Screen('DrawLines')
%
% 
% 2011?      kme Wrote it
% 2013?      lnk Cave_samsung addendum added by ktz, 2013. rest is untouched.
%                (added more vairables to the d2p function call and increased 
%                number of ticks)
% 12/12/2013 jly Updated help text and robustified screensize calculation
% 05/30/2014 jk  couple of changes:
%                  output is now in pixels
%                  grid is now made of '+'s instead of 'L's
%                  converted loops to one liners 
% 2017-08-14 tbc Converted one liners to functional form
%                  less tick redundancy (~80 fewer)

if nargin < 1
    help initTicks
    return
end

%% functional form of tick init
gridSize_sm = 1; % (deg)
gridSize_lg = 5; % large grid must be a multiple of small grid (...a reasonable constraint, amirite)
tickSize = 0.05 * p.static.display.ppd;  % (deg)

hgrid = gridSize_sm:gridSize_sm:(p.static.display.width/2);
vgrid = gridSize_sm:gridSize_sm:(p.static.display.height/2);

[xgrid, ygrid] = meshgrid( [0, -hgrid, hgrid], [0, -vgrid, vgrid]);
tgrid = [xgrid(:), ygrid(:)];

% make tick endpoints for each grid location
tks = zeros([ size(ygrid), 3]);
tks(:,:,1) = 1;
tks(:,:,2) = ~rem(xgrid, gridSize_lg); % identify large grid columns
tks(:,:,3) = ~rem(ygrid, gridSize_lg); % identify large grid rows
tks = tks(:,:,1) + (tks(:,:,2) & tks(:,:,3));
tks = tks(:);

% remove redundancy
[tgrid, di] = unique(tgrid, 'rows');
tks = tks(di);

% limit to only large spacing & on-axis ticks
i = prod(tgrid,2)==0 | tks>1;
tgrid = tgrid( i, :);
tks = tks(i);

% Convert grid points to projection mapped pixels & add tick lengths to each
% horizontal ticks
i = (tgrid(:,1)==0 & tgrid(:,2)~=0) | tks>1;
tpos = pds.deg2px(kron(tgrid(i,:), [1;1])', p.static.display.viewdist, p.static.display.w2px)'...
       + kron(tks(i), tickSize*[-1,0; 1,0]);
% vertical ticks
i = (tgrid(:,2)==0 & tgrid(:,1)~=0) | tks>1;
tpos = [tpos; pds.deg2px(kron(tgrid(i,:), [1;1])', p.static.display.viewdist, p.static.display.w2px)'...
              + kron(tks(i), tickSize*[0,-1; 0,1])];
          
% pass out
p.trial.pldaps.draw.grid.tick_line_matrix = tpos';

end %main function
