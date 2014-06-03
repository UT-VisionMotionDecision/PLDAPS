function dv = initTicks(dv)
% dv = initTicks(dv)
% Initialize grid of tick marks for Screen('DrawLines')
% initTicks creates a matrix for drawing tick marks on the human display 
% spaced every degree of visual angle. This grids up the screen into 1? and
% 5? step sizes so the experimenter can easily see the eccentricity of the
% stimulus. Set dv.trial.pldaps.draw.grid.use=true if you want ticks on your
% display. 
% 
% INPUTS:
%   dv [class]
%     .trial [struct] - main variables structure (see PLDAPShelp)
%       .display   - display structure 
%           .dWidth screen width in degree
%           .dHeight screen height in degree
% OUTPUTS:
%   dv [class]
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
%                  TODO: insert initGrid into some pldaps function that
%                  gets called in run.

if nargin < 1
    help initTicks
    return
end

small_tick_length = 2;%dv.px2deg([3/2;0]);% 3  % pixels
small_tick_length=small_tick_length(1);
big_tick_length = 5;%;dv.px2deg([11/2;0]); %10;   % pixels
big_tick_length = big_tick_length(1);

screen_size_h = floor(dv.trial.display.dWidth/2);
screen_size_v = floor(dv.trial.display.dHeight/2);

small_vert_degrees=-screen_size_v:screen_size_v;
small_horiz_degrees=-screen_size_h:screen_size_h;

big_grid_size=5;
screen_size_h = floor(screen_size_h/big_grid_size)*big_grid_size;
screen_size_v = floor(screen_size_v/big_grid_size)*big_grid_size;

big_vert_degrees=-screen_size_v:big_grid_size:screen_size_v;
big_horiz_degrees=-screen_size_h:big_grid_size:screen_size_h;

small_horizontal_matrix=deg2px(dv,[reshape(repmat(small_horiz_degrees,[2,1]),1,2*length(small_horiz_degrees)); zeros(1,2*length(small_horiz_degrees))]);
small_horizontal_matrix(2,:)= small_horizontal_matrix(2,:)+repmat([-small_tick_length small_tick_length],[1,length(small_horiz_degrees)]);
    
small_vertical_matrix=deg2px(dv,[zeros(1,2*length(small_vert_degrees)); reshape(repmat(small_vert_degrees,[2,1]),1,2*length(small_vert_degrees))]);
small_vertical_matrix(1,:)=small_vertical_matrix(1,:)+repmat([-small_tick_length small_tick_length],[1,length(small_vert_degrees)]);

big_horizontal_matrix=deg2px(dv,[reshape(repmat(big_horiz_degrees,[2,1]),1,2*length(big_horiz_degrees)); zeros(1,2*length(big_horiz_degrees))]);
big_horizontal_matrix(2,:)=big_horizontal_matrix(2,:)+repmat([-big_tick_length big_tick_length],[1,length(big_horiz_degrees)]);

big_vertical_matrix=deg2px(dv,[zeros(1,2*length(big_vert_degrees));reshape(repmat(big_vert_degrees,[2,1]),1,2*length(big_vert_degrees))]);
big_vertical_matrix(1,:)=big_vertical_matrix(1,:)+repmat([-big_tick_length big_tick_length],[1,length(big_vert_degrees)]);

big_vertical_grid_matrix=deg2px(dv,[reshape(repmat(big_horiz_degrees,[2*length(big_vert_degrees),1]),1,2*length(big_horiz_degrees)*length(big_vert_degrees)); ...
repmat(reshape([big_vert_degrees; big_vert_degrees],1,2*length(big_vert_degrees)), [1, length(big_horiz_degrees)])]);
big_vertical_grid_matrix(2,:)=big_vertical_grid_matrix(2,:)+...
repmat(reshape([-small_tick_length; small_tick_length],1,2), [1, length(big_horiz_degrees)*length(big_vert_degrees)]);

big_horizontal_grid_matrix=deg2px(dv,[repmat(reshape([big_horiz_degrees; big_horiz_degrees],1,2*length(big_horiz_degrees)), [1, length(big_vert_degrees)]);...
    reshape(repmat(big_vert_degrees,[2*length(big_horiz_degrees),1]),1,2*length(big_vert_degrees)*length(big_horiz_degrees))]);
big_horizontal_grid_matrix(1,:)=big_horizontal_grid_matrix(1,:)+...
    repmat(reshape([-small_tick_length;small_tick_length],1,2), [1, length(big_vert_degrees)*length(big_horiz_degrees)]);


line_matrix = [small_horizontal_matrix,small_vertical_matrix,big_horizontal_matrix,big_vertical_matrix,big_vertical_grid_matrix,big_horizontal_grid_matrix];

dv.trial.pldaps.draw.grid.tick_line_matrix = line_matrix;


% small_horizontal_matrix=[reshape(repmat(small_horiz_degrees,[2,1]),1,2*length(small_horiz_degrees)); repmat([-small_tick_length small_tick_length],[1,length(small_horiz_degrees)])];
% small_vertical_matrix=[repmat([-small_tick_length small_tick_length],[1,length(small_vert_degrees)]); reshape(repmat(small_vert_degrees,[2,1]),1,2*length(small_vert_degrees))];
% big_horizontal_matrix=[reshape(repmat(big_horiz_degrees,[2,1]),1,2*length(big_horiz_degrees)); repmat([-big_tick_length big_tick_length],[1,length(big_horiz_degrees)])];
% big_vertical_matrix=[repmat([-big_tick_length big_tick_length],[1,length(big_vert_degrees)]);reshape(repmat(big_vert_degrees,[2,1]),1,2*length(big_vert_degrees))];
% 
% big_vertical_grid_matrix=[reshape(repmat(big_horiz_degrees,[2*length(big_vert_degrees),1]),1,2*length(big_horiz_degrees)*length(big_vert_degrees)); ...
% repmat(reshape([big_vert_degrees-small_tick_length; big_vert_degrees+small_tick_length],1,2*length(big_vert_degrees)), [1, length(big_horiz_degrees)])];
% 
% big_horizontal_grid_matrix=[repmat(reshape([big_horiz_degrees-small_tick_length; big_horiz_degrees+small_tick_length],1,2*length(big_horiz_degrees)), [1, length(big_vert_degrees)]);...
%     reshape(repmat(big_vert_degrees,[2*length(big_horiz_degrees),1]),1,2*length(big_vert_degrees)*length(big_horiz_degrees))];
% 
% line_matrix = [small_horizontal_matrix,small_vertical_matrix,big_horizontal_matrix,big_vertical_matrix,big_vertical_grid_matrix,big_horizontal_grid_matrix];
% 
% dv.trial.pldaps.draw.grid.tick_line_matrix = dv.deg2px(line_matrix);


% screen_size_h = dv.trial.display.winRect(3)/dv.trial.display.ppd; 
% screen_size_v = dv.trial.display.winRect(4)/dv.trial.display.ppd; 
% 
% screen_size_h = dv.px2deg([dv.trial.display.winRect(3)/2;0]); 
% screen_size_v = dv.px2deg([0;dv.trial.display.winRect(4)/2]); 
%
% sH = 0:screen_size_h/2;
% bH = 0:5:screen_size_h/2;
% sV = 0:screen_size_v/2;
% bV = 0:5:screen_size_v/2;
% 
% 
% small_vert_degrees  = [-sV(2:end) sV];
% small_horiz_degrees = [-sH(2:end) sH];
% big_vert_degrees    = [-bV(2:end) bV];
% big_horiz_degrees   = [-bH(2:end) bH];
% 
% line_matrix = [];
% for i = 1:length(small_horiz_degrees)
%     line_matrix = [line_matrix,[small_horiz_degrees(i) small_horiz_degrees(i);pix2deg([0 small_tick_length],dv)]];
% end
% 
% small horizontal matrix
% for i = 1:length(small_vert_degrees)
%     line_matrix = [line_matrix,[pix2deg([0 small_tick_length],dv);small_vert_degrees(i) small_vert_degrees(i)]];
% end
% 
% big vertical matrix
% for i = 1:length(big_horiz_degrees)
%     line_matrix = [line_matrix,[big_horiz_degrees(i) big_horiz_degrees(i);pix2deg([0 big_tick_length],dv)]];
% end
% 
% big horizontal matrix
% for i = 1:length(big_vert_degrees)
%     line_matrix = [line_matrix,[pix2deg([0 big_tick_length],dv);big_vert_degrees(i) big_vert_degrees(i)]];
% end
% 
% big horizontal matrix
% for i = 1:length(big_horiz_degrees)
%     for j = 1:length(big_vert_degrees)
%         line_matrix = [line_matrix,[big_horiz_degrees(i) big_horiz_degrees(i);big_vert_degrees(j) big_vert_degrees(j)+pix2deg(small_tick_length,dv)]];
%         line_matrix = [line_matrix,[big_horiz_degrees(i) big_horiz_degrees(i)+pix2deg(small_tick_length,dv);big_vert_degrees(j) big_vert_degrees(j)]];
%     end
% end
% 
% dv.trial.display.tick_line_matrix = line_matrix;


end
% 
%     
% 
% % inline functions
% function d = pix2deg(x, dv)
% 
% d = x / dv.trial.display.ppd;
% end
% 








