function dv = initTicks(dv)
% dv = initTicks(dv)
% Initialize grid of tick marks for Screen('DrawLines')
% initTicks creates a matrix for drawing tick marks on the human display 
% spaced every degree of visual angle. This grids up the screen into 1° and
% 5° step sizes so the experimenter can easily see the eccentricity of the
% stimulus. Put it in your condition funciton if you want ticks on your
% display. 
% 
% INPUTS:
%   dv [struct] - main display variables structure (see PLDAPShelp)
%       .disp   - display structure 
%           .winRect [double 1 x 4] pixel coordinates [0 0 width height]
%           .ppd     [double 1 x 1] pixels per degree scalar 
% OUTPUTS:
%   dv [struct] - display variables (modified)
%       .disp   - display stucture  (modified)
%           .tick_line_matrix - field added in format called by
%                               Screen('DrawLines')
%

% 2011?      kme Wrote it
% 2013?      lnk Cave_samsung addendum added by ktz, 2013. rest is untouched.
%                (added more vairables to the d2p function call and increased 
%                number of ticks)
% 12/12/2013 jly Updated help text and robustified screensize calculation

if nargin < 1
    help initTicks
    return
end

small_tick_length = 3;  % pixels
big_tick_length = 10;   % pixels


screen_size_h = dv.disp.winRect(3)/dv.disp.ppd; 
screen_size_v = dv.disp.winRect(4)/dv.disp.ppd; 

sH = 0:screen_size_h/2;
bH = 0:5:screen_size_h/2;
sV = 0:screen_size_v/2;
bV = 0:5:screen_size_v/2;


small_vert_degrees  = [-sV(2:end) sV];
small_horiz_degrees = [-sH(2:end) sH];
big_vert_degrees    = [-bV(2:end) bV];
big_horiz_degrees   = [-bH(2:end) bH];



line_matrix = [];
for i = 1:length(small_horiz_degrees)
    line_matrix = [line_matrix,[small_horiz_degrees(i) small_horiz_degrees(i);pix2deg([0 small_tick_length],dv)]];
end

% small horizontal matrix
for i = 1:length(small_vert_degrees)
    line_matrix = [line_matrix,[pix2deg([0 small_tick_length],dv);small_vert_degrees(i) small_vert_degrees(i)]];
end


% big vertical matrix
for i = 1:length(big_horiz_degrees)
    line_matrix = [line_matrix,[big_horiz_degrees(i) big_horiz_degrees(i);pix2deg([0 big_tick_length],dv)]];
end

% big horizontal matrix
for i = 1:length(big_vert_degrees)
    line_matrix = [line_matrix,[pix2deg([0 big_tick_length],dv);big_vert_degrees(i) big_vert_degrees(i)]];
end

% big horizontal matrix
for i = 1:length(big_horiz_degrees)
    for j = 1:length(big_vert_degrees)
        line_matrix = [line_matrix,[big_horiz_degrees(i) big_horiz_degrees(i);big_vert_degrees(j) big_vert_degrees(j)+pix2deg(small_tick_length,dv)]];
        line_matrix = [line_matrix,[big_horiz_degrees(i) big_horiz_degrees(i)+pix2deg(small_tick_length,dv);big_vert_degrees(j) big_vert_degrees(j)]];
    end
end
dv.disp.tick_line_matrix = line_matrix;




end

    

% inline functions
function d = pix2deg(x, dv)

d = x / dv.disp.ppd;
end









