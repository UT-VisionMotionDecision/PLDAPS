function pldapsDrawDotsGL(xyz, isRel, dotsz, dotcolor, center3D, dotType, glslshader)
% Streamlined version of PTB moglDrawDots3d.m (circa ver. 3.0.14)
%   -- Removes preliminary safety checks
% Draw a large number of dots in 3D very efficiently.
%
% Usage: moglDrawDots3D(windowPtr, xyz [,dotdiameter] [,dotcolor] [,center3D] [,dotType] [, glslshader]);
%
% This function is the 3D equivalent of the Screen('DrawDots') subfunction
% for fast drawing of 2D dots. It has mostly the same paramters as that
% function, but extended into the 3D domain. It accepts a subset of the
% parameters for that function, ie., it is less liberal in what it accepts,
% in order to allow for simpler code and maximum efficiency.
%
% As a bonus, it accepts one additional parameter 'glslshader', the
% optional handle to a GLSL shading program, e.g., as loaded from
% filesystem via LoadGLSLProgram().
%
% The routine will draw into the 3D OpenGL userspace rendering context of
% onscreen window or offscreen window (or texture) 'windowPtr'. It will
% do so assuming that it is already active in 3D mode (between 'BeginOpenGL'
% & 'EndOpenGL' calls, and that the stereo projection & eye's modelview
% have been setup prior to this call. This is to avoid redundant & expensive
% context setup/switches between 2D & 3D modes
%
% Parameters and their meaning:
%
% 'windowPtr' Handle of window or texture to draw into.
% 'xyz' A 3-by-n or 4-by-n matrix of n dots to draw. Each column defines
% one dot to draw, either as 3D position (x,y,z) or 4D position (x,y,z,w).
% Must be a double matrix!
%
% 'dotdiameter' optional: Either a single scalar spec of dot diameter, or a
% vector of as many dotdiameters as dots 'n', or left out. If left out, a
% dot diameter of 1.0 pixels will be used. Drawing of dots of different
% sizes is much less efficient than drawing of dots of identical sizes! Try
% to group many dots of identical size into separate calls to this function
% for best performance!
%
% 'dotcolor' optional: Either a 3 or 4-component [R,G,B] or [R,G,B,A] color
% touple with a common drawing color, or a 3-by-n or 4-by-n matrix of
% colors, one [R;G;B;A] column for each individual dot. A common color for
% all dots is faster.
%
% 'dotType' optional: A setting of zero will draw rectangular dots, a
% setting of 1 will draw round dots, a setting of 2 will draw round dots of
% extra high quality if the hardware supports that. For anti-aliased dots
% you must select a setting of 1 or 2 and enable alpha blending as well.
%
% 'glslshader' optional: If omitted, shading state is not changed. If set
% to zero, then the standard fixed function OpenGL pipeline is used, like
% in Screen('DrawDots') (under most circumstances). If a positive
% glslshader handle to a GLSL shading program object is provided, that
% shader program will be used. You can use this, e.g., to bind a custom vertex
% shader to perform complex per-dot calculations very fast on the GPU.
%
% See 

% History:
% 03/01/2009  mk  Written.

% Need global GL definitions:
global GL;

if nargin <2
    error('Not enough inputs to %s. Must at least provide xyz position & flag for absolute or relative position state.',mfilename);
end

if isempty(isRel)
    isRel = false;
end

nvc = size(xyz, 1);
ndots = size(xyz, 2);

if ~(nvc == 3 || nvc == 4) || ndots < 1
    error('"xyz" argument must have 3 or 4 rows for x,y,z or x,y,z,w components and at least 1 column for at least one dot to draw!');
end

if nargin < 3 || isempty(dotsz)
    dotsz = 2;
end

nsizes = length(dotsz);
if ~isvector(dotsz) || (nsizes~=1 && nsizes~=ndots)
    error('"dotdiameter" argument must be a vector with same number of elements as dots to draw, or a single scalar value!');
end

if nargin < 4 || isempty(dotcolor)
    dotcolor = [1 1 1 1]';
end

% Proper orientation of color vector: 1 column per dot, 3[4] rows == RGB[A]
if (size(dotcolor, 1) == 1) && ((size(dotcolor, 2)==4) || (size(dotcolor, 2)==3))
    dotcolor = dotcolor';
end

ncolors = size(dotcolor, 2);
ncolcomps = size(dotcolor, 1);
if ncolcomps ~=4 
    if ncolcomps ==3  % fill in with alpha==1
        dotcolor(4,:) = 1;
    elseif  ncolors~=1 && ncolors~=ndots
        error('"dotcolor" must be a matrix with 3 or 4 rows and at least 1 column, or as many columns as dots to draw!');
    end
end

if nargin < 5
    % Default to "no center set"; all positions relative to observer (@ glLoadIdentity) :
    center3D = [];
end

if nargin < 6 || isempty(dotType)
    % Default to use gluDisk mode (with 22 slices):
    dotType = 22;
end
% must be integer input, so impose by setting class here
dotType = uint8(dotType);

if nargin < 7
    % Default to no change of shader bindings:
    glslshader = [];
end

%% Basic params & flags from the p.trial.display structure
if dotType>2
    % 3D opject sizes are radians, but typical unit expectation is dot diameter
    dotsz = dotsz./2;
end

%% Drawing loop

% Was a 'center3D' argument specified?
if ~isempty(center3D)
    % Create a marker to return this view to same state as before
    glPushMatrix;
    
    if numel(center3D)==3
        % single translation to new center
        glTranslated(center3D(1), center3D(2), -center3D(3));
        
    elseif size(center3D,1)==16 && numel(center3D)==16
        % is a modelview matrix? (in column-major form)
        glMultMatrixd(center3D(:));
        
    else
        % is an n-by-4 series rotations and/or translations
        for rti = 1:size(center3D,1)
            % glRotated requires 4 inputs, but glTranslated only 3; so use
            % the presence or absence of a numerical 4th input as a switch
            if ~isnan(center3D(rti,4))
                glRotated(center3D(rti,1), center3D(rti,2), center3D(rti,3), center3D(rti,4));
            else
                glTranslated(center3D(rti,1), center3D(rti,2), -center3D(rti,3));
            end
        end
    end
end

%% Fork to draw as gluDisk (new 3d-centric mode)  -- or --  as GL.POINTS (2d-centric; typ. Screen('DrawDots') mode)
% [dotType] == 0,1, or 2 define classic dot style/anti-aliasing modes
% [dotType] >= 3 will be used gluDisk resolution parameter (n-slices)
%               (12-30 is good...depends on size/position range of your stim, so must leave up to experimenter)
useDiskMode = dotType >2;

if useDiskMode
    %% Draw as 3D objects
    
    if ~isRel
        % get relative translation steps between each dot for faster drawing
        xyz = diff([[0 0 0]', xyz], 1,2);
    end

    % No choice but to draw each 'dot' in a loop, so expand size indices
    % Dot size
    if nsizes > 1
        ii = 1:ndots;
    else
        ii = ones(1, ndots);
    end
    
    % diskQuadric = gluNewQuadric;  % Quad only needed for gluDisk, which is degenerate & not much faster than spheres

    % Loop through each dot
    glPushMatrix;
    if ncolors == 1
        % Set color just once
        %   (TBC: setting color on each dot draw can add up to ~10-20% total execution time)
        glColor4fv( dotcolor(:,1) );
        for i = 1:ndots
            % set position
            glTranslated(xyz(1,i), xyz(2,i), -xyz(3,i));
            % glTranslated(xyz(1,i), xyz(2,i), xyz(3,i));
            % draw it:  gluDisk( quad, inner, outer, slices, loops );  inner always == 0...our dots are unholy!
            % moglcore('gluDisk', diskQuadric, 0, dotsz(:,ii(1,i)), dotType, 1);
            moglcore( 'glutSolidSphere', dotsz(:,ii(1,i)), dotType, dotType/2);
            % moglcore( 'glutSolidTeapot', dotsz(:,ii(1,i)) );
        end
    else
        for i = 1:ndots
            % set position
            glTranslated(xyz(1,i), xyz(2,i), -xyz(3,i));
            % set color
            glColor4fv( dotcolor(:,i) );
            % moglcore('gluDisk', diskQuadric, 0, dotsz(:,ii(1,i)), dotType, 1);
            moglcore( 'glutSolidSphere', dotsz(:,ii(1,i)), dotType, dotType/2);
        end
    end
    glPopMatrix;

    % gluDeleteQuadric(diskQuadric);
    
else
    %% draw dots as GL.POINTS (like normal PTB; super fast, but size defined in pixels, not space!)

    if isRel
        % vertex array expects absolute positions of each dot
        xyz = cumsum( xyz );
    end
    
    % Point smoothing wanted?
    if dotType > 0
        
        glEnable(GL.POINT_SMOOTH);
        
        if dotType > 1
            % A dot type of 2 requests for highest quality point smoothing:
            glHint(GL.POINT_SMOOTH_HINT, GL.NICEST);
        else
            glHint(GL.POINT_SMOOTH_HINT, GL.DONT_CARE);
        end
    end
    
    % Pass a pointer to the start of the point-coordinate array:
    glVertexPointer(nvc, GL.DOUBLE, 0, bsxfun(@times, xyz, [1;1;-1]));
    
    % Enable fast rendering of arrays:
    glEnableClientState(GL.VERTEX_ARRAY);
    
    % Multiple colors, one per dot, provided?
    if ncolors > 1
        % Yes. Setup a color array for fast drawing:
        glColorPointer(ncolcomps, GL.DOUBLE, 0, dotcolor);
        glEnableClientState(GL.COLOR_ARRAY);
    else
        % No. Just set one single common color:
        if ncolcomps == 4
            glColor4dv(dotcolor);
        else
            glColor3dv(dotcolor);
        end
    end
    
    % Change of shader binding requested?
    if ~isempty(glslshader)
        % Backup old shader binding:
        oldShader = glGetIntegerv(GL.CURRENT_PROGRAM);
        
        % Set new one:
        glUseProgram(glslshader);
    end
    
    % dotdiameter per dot defined?
    if nsizes > 1
        % Yes :-( -- Need to iterate over all dots and set each dots size
        % individually in immediate mode. This is sloooow:
        for i=1:ndots
            % Set dotsize:
            glPointSize(dotsz(i));
            
            % Submit vertex for drawing of this dot:
            glDrawArrays(GL.POINTS, i-1, 1);
        end
    else
        % No :-) -- We can use a single call for fast batch-drawing of all
        % points with a common size:
        glPointSize(dotsz);
        glDrawArrays(GL.POINTS, 0, ndots);
    end
end

%% Clean up
if ~isempty(glslshader)
    % Reset old shader binding:
    glUseProgram(oldShader);
end

if ~useDiskMode % clean up after drawing GL.POINTS
    if ncolors > 1
        % Disable color array for fast drawing:
        glColorPointer(ncolcomps, GL.DOUBLE, 0, 0);
        glDisableClientState(GL.COLOR_ARRAY);
    end
    
    % Disable fast rendering of arrays:
    glDisableClientState(GL.VERTEX_ARRAY);
    glVertexPointer(nvc, GL.DOUBLE, 0, 0);
    
    if dotType > 0
        glDisable(GL.POINT_SMOOTH);
    end
    
    % Reset dot size to 1.0:
    glPointSize(1);
    
end % No specific glDisk/Sphere drawing clean up to do (...maybe once an indexed list drawing method is found)


if ~isempty(center3D)
    % Restore old modelview matrix from backup:
    glPopMatrix;
end


end
