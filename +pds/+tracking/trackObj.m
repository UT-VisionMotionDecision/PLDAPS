classdef trackObj < handle
    % PLDAPS tracking object replaces struct in [p.static.tracking]
    % - allows for storage & handoff of calibration data to & from PLDAPS and the eyeCalApp GUI (pds.tracking.eyeCalApp)
    %
    % see also: pds.tracking, pds.display.pdsDisplay
    %
    % TODO METHODS:
    % updateViewDist - add listener for changes to p.static.display.viewdist, if changed:
    %                -- update targets struct so points are in appropriate visual degrees
    %                -- update calibration transform (calc matrix from fixations, IF NONE: pause & notify user)
    
    
    properties (Access = public)
        updateFxn@struct    % set of function handles to tracked device(s); e.g. pds.mouse.updateFxn.m
        calPath@struct      % paths to loaded/saved calibration data == struct('source',[],'saved',[]);
        source
        tform               
        gridSz              % target grid size ([x,y] in vis. deg)
        fixations           % 3-by-n matrix of complex XYZ data for fixation target & raw track positions, as:
                            % == [xTarget, yTarget, zTarget] + 1i.*[xRaw, yRaw, viewDist]
                            % Thus:  xyzTarget = real(fixations(:,n));   xyzEye = imag(fixations(:,n));
        thisFix = 0;        % basic counter of current index into fixation matrix
        
    end

    properties (Transient)
        % These properties shoud/need not be saved
        srcIdx
        targets@struct      % calibration [fixation] target struct
                            % initialized with deg2pix conversions upon creation
    end
    properties (Hidden, Transient)
        % Only allow handle to display object to be set during initial object construction
        % - Consider .display prevent overwrite w/ , SetAccess = immutable
        display             % handle to pldaps display object (p.static.display)
        dotBuffers          % necessary for certain glDraw 3D rendering
        
        nextTarg
        minSamples = 10;
        
        handles
    end
    
    methods (Access = public)
        
        % Constructor
        function obj = trackObj(varargin)
            % first input must be pldaps object
            p = varargin{1};
            
            % Copy variables from pldaps
            obj.display = p.static.display;
            
            % Listener:  .display.viewdist
            dh = p.static.display; % cannot create listener from handle inside of pldaps class
            %viewDistSet
%             obj.handles.vd = listener(dh,'viewDistSet', @obj.viewDistUpdate);
%             obj.handles.vd = listener(dh,'viewDistSet', @pds.tracking.trackObj.viewDistUpdate);
            % addlistener(dh,'viewdist','PostGet', @obj.viewDistUpdate);
            addlistener(dh,'viewdist','PostSet', @obj.viewDistUpdate);
            %             obj.handles.zf = listener(dh,'zFar','PostSet', @obj.viewDistUpdate);
            
            % tracking source device (string of pldaps module fieldname)
            obj.source = p.trial.tracking.source;
            % index of tracked elements:  e.g. 1==leftEye, 2==rightEye, [1,2]==binocular
            obj.srcIdx = p.trial.tracking.srcIdx;
            % size of calibration target grid
            % TODO: this should have a default set and/or be determined by field in tracking source (p.trial.<source>)
            obj.gridSz = p.trial.tracking.gridSz;

            % Initialize basic params
            obj.fixations = nan(3, obj.minSamples, max(obj.srcIdx));

            % initialize tform from pldaps structure
            obj.updateTform(p);
            
            % initialize targets
            obj.setupTargets;
            
        end
        
        % % %         %% Listener:  .display.viewdist
        % % %         function viewDistListener(ds)
        % % %             if nargin>0 && contains(class(ds),'pdsDisplay')
        % % %                 addlistener(ds, 'viewdist', 'PostSet', @trackObj.viewDistUpdate);
        % % %             end
        % % %         end %viewDistListener
            
        
        %% updateTform
        function updateTform(obj, varargin)
            
            if nargin<2 %|| isa(varargin{1},'trackObj')
                % update tform using fixation data in trackObj
                
                % find all recorded fixations that match current viewdist
                n = imag(obj.fixations(3,:,obj.srcIdx(1))) == obj.display.viewdist;
                minSamps = 10;
                
                if sum(n)>=minSamps % minimum number of data points to perform fit
                    %% Fit calibration to fixation data
                    for i = obj.srcIdx
                        % Decompose raw tracking data and target positions from calibration data (p.trial.tracking.fixations)
                        xyRaw = imag(obj.fixations(:, n, i));  % only raw vals should be stored in fixations.
                        targXY = real(obj.fixations(:, n, i));
                        
                        % Fit geometric transform
                        % - tform types: ['nonreflective', 'affine', 'projective', 'polynomial']  ...make this selectable based on source field
                        % - eye/target data are input conceptually backwards, but polynomial tform methods are limited to inverse transform
                        obj.tform(i) = fitgeotrans(targXY(1:2,:)', xyRaw(1:2,:)', 'polynomial',3);
                        
                        fprintf('Tracking calibration [%d] updated for viewdist %scm\n', i, num2str(obj.display.viewdist));
                        
                        % group all of these distance measurements together (makes adding/removing points otf more feasible)
                        obj.fixations(:,:,i) = [obj.fixations(:, ~n, i), obj.fixations(:, n, i)];
                        
                    end
                    
                else
                    fprintf(2, '~!~\tInsufficient(<%d) fixation samples for calibration update.\n', minSamps);
                end
                
            elseif isa(varargin{1},'pldaps')
                % initialize tform from p.trial
                p = varargin{1};
                % expand source index (mostly to deal with tracking rightEye(2) only)
                if isscalar(obj.srcIdx) && obj.srcIdx>1
                    si = 1:obj.srcIdx;
                else
                    si = obj.srcIdx;
                end
                
                if ~isfield(p.trial.tracking,'tform') || isempty(p.trial.tracking.tform)
                    % [POLYNOMIAL] requires manual setup
                    %   - all lesser indices must exist, else poly tform object construction fails
                    %   - all indexed tform methods must match...therefore, initialization must be consistent
                    %   - 2nd degree (...doesn't quite track periphery well)
                    % 3rd degree
                    obj.tform = deal(images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0 0 0 0 0], [0 0 1 0 0 0 0 0 0 0]));
                    % set, then expand (prevent class consistency error)
                    if numel(si)>1 || si>1
                        obj.tform(si) = deal(images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0 0 0 0 0], [0 0 1 0 0 0 0 0 0 0]));
                    end
                    
                    fprintf('~~~\tCalibration transform %s initialized\n', mat2str(si))

                else
                    obj.tform = p.trial.tracking.tform;
                    if size(obj.tform)~=si
                        obj.tform(si) = deal(obj.tform);
                    end
                end
                
            elseif isstruct(varargin{1})
                % use struct fields to update tracking object
                Sin = varargin{1};
                fn = fieldnames(Sin);
                for i = 1:length(fn)
                    if isprop(obj,fn{i})
                        obj.(fn{i}) = Sin.(fn{i});
                    else
                        fprintf('~!~\tTracking object prop %s does not exist, could not set from loaded struct\n', fn{i});
                    end
                end
            else
                keyboard
            end
        end %updateTform
        

        %% setupTargets
        function setupTargets(obj, varargin)
            %function targets = pds.tracking.setupTargets_9pt(p)
            %
            % Create 9-point tracking calibration target positions struct
            %   .gridSz defines [x,y] range of target positions in visual degrees
            %   
            % TODO:  parameterize number of targets
            %
            targets = struct();
            
            halfWidth_x = obj.gridSz(1)/2;
            halfWidth_y = obj.gridSz(end)/2;
            
            % basic 9-point target grid (in degrees)
            xx = -halfWidth_x:halfWidth_x:halfWidth_x;
            yy = -halfWidth_y:halfWidth_y:halfWidth_y;
            [xx, yy] = meshgrid(xx, yy);
            % arrange first 9 to match numpad
            xy = sortrows([xx(:),yy(:)], [-2,1]);
            if 1
                % add inner target points
                [x2, y2] = meshgrid( halfWidth_x/2*[-1 1], halfWidth_y/2*[1 -1]);
                xy = [xy; [x2(:), y2(:)]];
            end
            zz = zeros(size(xy,1),1);
            
            targets.targPos = [xy, zz(:)]' ;
            % Target position in WORLD coordinates [CM]
            % add targPos to the viewDist baseline for final depth in world coordinates
            targets.targPos(3,:) = targets.targPos(3,:) + obj.display.viewdist;
            % % Ideally draw in 3D:
            %   % convert XY degrees to CM, given the distance in depth CM
            %   targets.targPos(1:2,:) = pds.deg2world(targets.targPos(1:2,:)', targets.targPos(3,:), 0); % p.deg2world(p, p.trial.(sn).stimPosDeg(1:2)');      %
            % % ...use Pixels in a pinch
            targets.xyPx = pds.deg2px(targets.targPos(1:2,:), targets.targPos(3,:), obj.display.w2px,  0) + obj.display.ctr(1:2)';
            
            targets.timeUpdated = GetSecs;
            targets.nTargets = size(targets.targPos,2);
            targets.randOrd = randperm(targets.nTargets);
            
            % apply to object
            obj.targets = targets;
                
        end %setupTargets
        
        
    end %methods
    
    methods (Static)
        %% viewDistUpdate event callback
        function viewDistUpdate(src, evnt)
            disp('!')
            % For regular (non-property) events,
            % - src is handle to complete source object
            % - evnt contains .EventName string & .Source (same handle as above)
            % -- no knowledge of if/what changed
            % -- unclear how to produce AbortSet features of a property change event...
            switch evnt.EventName
                case 'PostSet'
                    fprintf('\n**\tviewdist updated to %6.2f cm\n',evnt.AffectedObject.viewdist); %src.viewdist)
            end
            
            %             try
            %                 switch src.Name
            %                     case 'zFar'
            %                         sprintf('\n**\tzFar updated to %2.2f\n',evnt.AffectedObject.zFar)
            %                     case 'viewdist'
            %                         sprintf('\n**\tviewdist updated to %6.2g\n',evnt.AffectedObject.viewdist)
            %                 end
            %             end
            
        end
    end
                   
end %classdef


% % % % % % % % %
%% Sub-Functions
% % % % % % % % %

