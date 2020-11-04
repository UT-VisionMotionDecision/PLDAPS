function dotBuffers = pldapsDrawDotsGL(xyz, dotsz, dotcolor, center3D, dotType, glslshader, dotBuffers)
% function dotBuffers = pldapsDrawDotsGL(xyz, dotsz, dotcolor, center3D, dotType, glslshader, dotBuffers)
% 
% Streamlined version of PTB moglDrawDots3d.m (circa ver. 3.0.14)
%   -- Removes preliminary safety checks
%   -- [dotType] controls 3D dot rendering mode/quality as:
%         0-2 	standard DrawDots type (square, anti-aliased, xtra-nice anti-aliased)
%         3-9   geodesic sphere resolution, n-3==icosahedron scale factor
%                   !!NOTE!! Requires OpenGL >= 3.3  (...only functional on Linux atm. --TBC Nov. 2017)
%                   [dotType]==[nSides]: 3==20, 4==80, 5==320, 6==1280, 7==5120, 8==20,480, 9==81,920 sides
%                   recommended: 5-6  (i.e. 320-1280 sides)
%         >=10  n-segments of a mercator sphere (...simple, but over-samples poles)
%                   recommended: 12-22;
%
% TODO: update help with new info on new params/shapes/defaults & usage examples.
%       ...[center3D] has a particularly tricky/flexible implementation .  --TBC 2019-12)
% 
% ~~~Orig help text below~~~ 
% Draw a large number of dots in 3D very efficiently.
%
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
% sizes is much less efficient than drawing of dots of identical sizes! Attempt
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
% See also:  PTB moglDrawDots3d.m

% History:
% 03/01/2009  mk  Written.
% 2017-xx-xx  TBC  Adapted from PTB moglDrawDots3d.m (circa ver. 3.0.14)
% 

% Need global GL definitions:
global GL;
    
if nargin <7 || isempty(dotBuffers)
    % initialize empty structure for OpenGL buffer objects
    dotBuffers = struct;
end
    
if nargin <2
    error('Not enough inputs to %s.',mfilename);
end

nvc = size(xyz, 1);
ndots = size(xyz, 2);

if ~(nvc == 3 || nvc == 4) || ndots < 1
    error('"xyz" argument must have 3 or 4 rows for x,y,z or x,y,z,w components and at least 1 column for at least one dot to draw!');
end

if nargin < 2 || isempty(dotsz)
    dotsz = 2;
else
    dotsz = dotsz(:);
end

nsizes = length(dotsz);
if ~isvector(dotsz) || (nsizes~=1 && nsizes~=ndots)
    error('"dotdiameter" argument must be a vector with same number of elements as dots to draw, or a single scalar value!');
end

if nargin < 3 || isempty(dotcolor)
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

if nargin < 4
    % Default to "no center set"; all positions relative to observer (@ glLoadIdentity) :
    center3D = [];
end

if nargin < 5 || isempty(dotType)
    % Default to use gluDisk mode (with 22 slices):
    dotType = 12;
else
    if ~IsLinux && (dotType>2 && dotType<10)
            dotType = dotType+7;
        persistent beenWarned %#ok<TLEV>
        if isempty(beenWarned)
            warning(['Attempted to use geodesic sphere rendering, but this machine is not Linux.\n',...
                '\tDowngrading dotType to %d for standard gluSphere dots (will be muuuch slower!).\n',...
                '\tFor more info, see help text of:  %s\n'], dotType, mfilename('fullpath'))
            beenWarned = true;
        end
    end
end
% must be integer input, so impose by setting class here
dotType = uint8(dotType);

if nargin < 6
    % Default to no change of shader bindings:
    glslshader = [];
end

%% Drawing loop
% Create a marker to return this view to initial state after drawing
glPushMatrix;

% Was a 'center3D' argument specified?
if ~isempty(center3D)
%     % Create a marker to return this view to same state as before
%     glPushMatrix;
    
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

%% Fork to draw as gluDisk (new 3d-centric modes)  -- or --  as GL.POINTS (2d-centric; typ. Screen('DrawDots') mode)
if dotType>2
    useDiskMode = 1;
    if dotType>9
        useDiskMode = 2;
        % gluSphere sizes need radius, but all others are diameter...normalize
        dotsz = dotsz./2;
    end
else
    useDiskMode = 0;
end
        % [dotType] is interpreted as follows:
        % 0-2 	standard DrawDots type (square, anti-aliased, xtra-nice anti-aliased)
        % 3-9   geodesic sphere resolution, n-3==icosahedron scale factor
        %           !!NOTE!! Requires OpenGL >= 3.3  (...currently Matlab on OSX limited to v.2.1 [wtf?!?] --TBC Nov. 2017)
        %           [dotType]==[nSides]: 3==20, 4==80, 5==320, 6==1280, 7==5120, 8==20,480, 9==81,920 sides
        %           recommended: 5-6  (i.e. 320-1280 sides)
        % >=10  n-segments of a mercator sphere (...simple, but over-samples poles)
        %           recommended: 12-22;


if useDiskMode==1
    %% Draw as 3D geodesic spheres (soo nice, but needs Linux atm.)

    % Dot size gets tacked onto xyz buffer data
    xyz(4,:) = dotsz(:);

    % Backup old shader binding:
    oldShader = glGetIntegerv(GL.CURRENT_PROGRAM);
    
    % Initialize buffers (only once!)
    if ~isfield(dotBuffers, 'glsl')
        % Load the speedy shader
        shaderpath = {which('geosphere.vert'), which('geosphere.frag')};%{fullfile(glslshader, 'geosphere.vert'), fullfile(glslshader, 'geosphere.frag')};
        dotBuffers.glsl = LoadGLSLProgramFromFiles(shaderpath, 0);
        % Set new one:
        glUseProgram(dotBuffers.glsl);
        
        [vv,ff] = glDraw.icosphere(dotType-3);
        % convert vv into direct triangles (...would be better if indexed vectors, but whatever)
        ff = ff';
        vv = 0.5*vv(ff(:),:)'; % expand indexing & convert to unit diameter (size == [3, ntriangles]);
        dotBuffers.ntris = size(vv,2);
        
        bytesPerEl = 4; % 4 should be sufficient for single()
        
        % vertex buffer
        % jnk = whos('vv'); dotBuffers.vert.mem=jnk.bytes; % gets memory size of var
        dotBuffers.vert.mem = numel(vv)*bytesPerEl; % will become GL.FLOAT, 4 bytes/el.  
        dotBuffers.vert.h = glGenBuffers(1);
        dotBuffers.vert.i = 0; % attribute index   (must correspond to init order inside shader)
        glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.vert.h);
        glBufferData(GL.ARRAY_BUFFER, dotBuffers.vert.mem, single(vv(:)), GL.STATIC_DRAW);
        
        % position buffer: [x, y, z, size]
        % Data will stream to this buffer for each frame
        %jnk = whos('xyz'); dotBuffers.pos.mem = jnk.bytes;  % gets memory size of var
        dotBuffers.pos.mem = numel(xyz)*bytesPerEl;  % 4 bytes/el.  
        dotBuffers.pos.h = glGenBuffers(1);
        dotBuffers.pos.i = 1; % attribute index
        glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.pos.h);
        glBufferData(GL.ARRAY_BUFFER, dotBuffers.pos.mem, single(xyz(:)), GL.STREAM_DRAW);
        
        % color buffer: [r, g, b, a]
        % Data will stream to this buffer for each frame
        % jnk = whos('col'); dotBuffers.col.mem = jnk.bytes;   % gets memory size of var
        dotBuffers.col.mem = numel(dotcolor)*bytesPerEl;  % 4 bytes/el.  
        dotBuffers.col.h = glGenBuffers(1);
        dotBuffers.col.i = 2; % attribute index
        glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.col.h);
        glBufferData(GL.ARRAY_BUFFER, dotBuffers.col.mem, single(dotcolor(:)), GL.STREAM_DRAW);
        
    else
        % Set new one:
        glUseProgram(dotBuffers.glsl);

        % Update position buffer (via "orphaning")
        glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.pos.h);
        glBufferData(GL.ARRAY_BUFFER, dotBuffers.pos.mem, 0, GL.STREAM_DRAW);
        glBufferSubData(GL.ARRAY_BUFFER, 0, dotBuffers.pos.mem, single(xyz(:)));
        
        % Update color buffer
        glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.col.h);
        glBufferData(GL.ARRAY_BUFFER, dotBuffers.col.mem, 0, GL.STREAM_DRAW);
        glBufferSubData(GL.ARRAY_BUFFER, 0, dotBuffers.col.mem, single(dotcolor(:)));
        
    end


    % vertex buffer
    glEnableVertexAttribArray(dotBuffers.vert.i);  %(GL attribute index starts at zero)
    glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.vert.h);
    glVertexAttribPointer(dotBuffers.vert.i, 3, GL.FLOAT, GL.FALSE, 0, 0);
    % pos & size buffer
    glEnableVertexAttribArray(dotBuffers.pos.i);
    glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.pos.h);
    glVertexAttribPointer(dotBuffers.pos.i, 4, GL.FLOAT, GL.FALSE, 0, 0);
    % color buffer
    glEnableVertexAttribArray(dotBuffers.col.i);
    glBindBuffer(GL.ARRAY_BUFFER, dotBuffers.col.h);
    glVertexAttribPointer(dotBuffers.col.i, 4, GL.FLOAT, GL.TRUE, 0, 0);

    % Assign buffer usage   (!!specific to glDrawArrays*Instanced*!!)
    % // The first parameter is the attribute buffer #
    % // The second parameter is the "rate at which generic vertex attributes advance when rendering multiple instances"
    glVertexAttribDivisorARB(0, 0); % particles vertices : always reuse the same n vertices -> 0
    glVertexAttribDivisorARB(1, 1); % positions : one per element (its center) -> 1
    glVertexAttribDivisorARB(2, 1); % color : one per element -> 1
    
    % % % % % %
    % DRAW IT!!
    % % % % % %
    glDrawArraysInstancedARB(GL.TRIANGLES, 0, dotBuffers.ntris, ndots);
    
    % disable dot attribute buffers & clean up
    glDisableVertexAttribArrayARB(0);
    glDisableVertexAttribArrayARB(1);
    glDisableVertexAttribArrayARB(2);
    
    % Reset old shader binding:
    glUseProgram(oldShader);

    
elseif useDiskMode==2
    %% Draw as Mercator spheres
    
    % get relative translation steps between each dot for faster drawing
    xyz = diff([[0 0 0]', xyz], 1,2);

    % No choice but to draw each 'dot' in a loop, so expand size indices
    % Dot size
    if nsizes > 1
        ii = 1:ndots;
    else
        ii = ones(1, ndots);
    end
    
    % Loop through each dot
    glPushMatrix; % center of dot cluster: all dot positions are relative to this (i.e. not streamed)
    if ncolors == 1
        % Set color just once
        %   (TBC: setting color on each dot draw can add 10-20% total execution time)
        glColor4fv( dotcolor(:,1) );
        for i = 1:ndots
            % set position
            glTranslated(xyz(1,i), xyz(2,i), -xyz(3,i));
            %fprintf('%8.3g\t%s\n', dotsz(ii(1,i)), mat2str(xyz(:,i), 3))
            moglcore( 'glutSolidSphere', single(dotsz(ii(1,i))), dotType, dotType);
        end
    else
        for i = 1:ndots
            % set position
            glTranslated(xyz(1,i), xyz(2,i), -xyz(3,i));
            % set color
            glColor4fv( dotcolor(:,i) );
            moglcore( 'glutSolidSphere', dotsz(ii(1,i)), dotType, dotType);
        end
    end
    glPopMatrix; % back to center
    
else
    %% Draw dots as GL.POINTS (like normal PTB; super fast, but size defined in pixels, not space!)

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
        glColorPointer(ncolcomps, GL.DOUBLE, 0, double(dotcolor));
        glEnableClientState(GL.COLOR_ARRAY);
    else
        % No. Just set one single common color:
        if ncolcomps == 4
            glColor4dv(double(dotcolor));
        else
            glColor3dv(double(dotcolor));
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
    
    if ~isempty(glslshader)
        % Reset old shader binding:
        glUseProgram(oldShader);
    end
end

%% Clean up

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
    
end % No specific Sphere drawing clean up to do


% if ~isempty(center3D)
    % Restore old modelview matrix from backup:
    glPopMatrix;
% end


end
