classdef condMatrix < dynamicprops
% p.condMatrix:  a handle class (w/dynamic properties) for controlling PLDAPS condition matrix
%
% Setup p.condMatrix conditions during experiment setup file/'pldaps wrapper function'
% ...a more functional replacement to old style p.conditions{}
% 
% For an example of behavioral control & interaction with condMatrix see:
%     glDraw.pmBase
% 
% ****************************************************************
% Name-value pair parameters:
% 
% [randMode]     (def: 0)
%   Randomize order of upcoming pass through condition matrix
%   -- if numel(.randMode) does not equal to number of dimensions in .conditions matrix,
%      then will be treated as a simple switch
%           case 1 % randomize across all dimensions
%           case 2 % randomize within columns w/ Shuffle.m
%           case 3 % randomize within rows (...this will fail with >3 condDims!)
%           otherwise % do nothing
%   -- else each dimension will be randomized separately using ShuffleMex.m
%        -- positive randMode values will randomize the numbered dimension
%        -- zero randMode values will do nothing to that dimension
%        -- negative randMode values will shuffle order of numbered dimension,
%           while maintaining all other dimension
%    EXAMPLE 1:
%       - condMatrix dimensions == (xpos, ypos, ori)
%       - .randMode = [1, 2, -3] will present cycle through each orientation,
%         present the same orientation at every xy location in random order,
%         then select a different random orientation --exclusive of already
%         presented oriientations-- present it at every xy location, etc, etc.
%    EXAMPLE 2:
%       - condMatrix dimensions == (direction, speed)
%       - .randMode = [2,-1]
% 
% [nPasses]      (def: inf)
%   Number of full passes through condition matrix
%   
% [useFrameDurations]    (def: false)
%   Flag for signaling the conversion of matrix module onset durations [.modOnDur]
%   from frame count to seconds.  ...this is hacky, but here for now
% 
% ****************************************************************
% SETUP EXAMPLE:
% % RF mapping stimulus with matrix of xy positions & drift directions
% % ...after creating the Pldaps opject (e.g.  p = pldaps(subj, settingsStruct); )
% 
%     %% Setup condition params
%     gridRes = 5;
%     xs = linspace(-10,10, gridRes);
%     ys = linspace(-10,10, gridRes);
%     dirInc = 90;
%     dirs = dirInc:dirInc:360;
%     % Make a fully crossed matrix
%     [xx, yy, dd] = ndgrid(xs, ys, dirs);
% 
%     %% Make a condition matrix cell 
%     c = cell(size(xx)); % *** maintain same shape as condition matrix source values
% 
%     % Fill with relevant fields of your matrixModule
%     for i = 1:numel(c)
%         % stim position
%         c{i}.stimPos    = [xx(i), yy(i)];
%         % motion direction
%         c{i}.dir        = dd(i);
%     end
% 
%     %% Add condition matrix to the pldaps structure
%     p.condMatrix.conditions = c;
%     % *** NOT p.conditions = c; % !! leave this empty, everything is in .condMatrix now
%     %
%     % Initialize the condMatrix object, passing control parameters as string-value pairs
%     p.condMatrix = condMatrix(p, 'randMode', [1,2,3], 'nPasses',inf);
% 
%     %% Run it!!
%     p.run;
% 
% ****************************************************************
% 
% Core Methods:
%   [nextCond]
%       Apply upcoming condition parameters for the nextTrial
%       - if Params Class is in use, this will:       (default behavior circa 2020, but will change at some point)
%       1) activate hierarchy levels from [p.static.pldaps.baseParamsLevels] 
%       2) [optional] create a new block level ( iff ~isempty(cm.blocks) ) with block-specific params, & add that level to the baseParamsLevels
%          - NOTE: prior blocks should [ideally] also be 'pruned' from hierarchy
%       3) create a new trial level, which will accumulate any updates to parameters/data for the upcoming trial
%          - a unique condition will be applied to each matrixModule instance, using set of module names defined in  [p.trial.pldaps.modNames.matrixModule]
%          - order of conditions based on [cm.order], which is setup/replenished for each pass following [cm.randMode] 
%          - condition index is assigned w/in each matrixModule as  [p.trial.(mN).condIndex], where [mN] is the fieldname of each unique matrix module
%          - See [modularDemo.pmBase.m] for example of how to use .condIndex and .baseIndex to send unique strobed values for each condition presented
% 
%   [putBack]
%       Supply feedback at end of trial to report which conditions were successfully presented
%       - condIndices of any matrixModules that were not [fully] shown (&& were not flagged as padding for last trial in a pass)
%         will be appended to the end of the current .order cueue of conditions.
%       - See [modularDemo.pmBase.m] for usage
% 
%
% see also:  glDraw.pmBase
% 
% 2018-xx-xx  TBC  Wrote it.
% 2019-08-30  TBC  Commenting and [some] cleanup
% 2020-12-08  TBC  Added [basic] block capibilities & ever more commenting/explanation
% 


properties (Access = public)    
    % --- Standard setup ---
    conditions  % cell of matrixModule fields that define each condition
    i           % index # of current position in .condMatrix.order
    iPass       % index # of current pass
    nPasses     % [inf] end experiment after nPasses through condition matrix
    order       % set of condition indices for the current pass
    condReps  % counter of fully presented condition indices
    passSeed    %[sum(100*clock)] base for random seed:  rng(.passSeed + .iPass, 'twister')
    
    randMode    % [0] flag for randomization through condition matrix [.condMatrix.conds] (see: condMatrix.updateOrder method)
    baseIndex   % [1000] base index value used to distinguish condition index strobed words, and as matrixModule onset strobe(?)

    modNames    % module names struct
    maxFrames   % max number of frames per trial

    % --- Block setup ---
    blocks      % cell of parameters to update after [n] full passes through condition matrix
    % Blocks are only updated at start of new Pass
    % Unlike matrixModules, blocks{} can modify ANY pldaps [p.trial] subfield or pldaps module
    % - e.g. changes to [p.trial.display.viewdist]  or  toggling broader 'modes' of your stimulus modules
    % - ...even matrixModules, but condition matrix parameters will take precident 
    iBlock      % index # of current block
                % TODO: allow randomization of block order
    blockModulo % modulus of block update increments: triggered when  ~mod(iPass-1, blockModulo);
    
end

properties (Access = public, Transient = true)
    % Don't include figure handles/objects in saved outputs
    H           = struct('infoFig',[]); % Handles to relevant objects (e.g. Info Figure)
        
end

properties (Access = private, Transient = true)
    % basic internal counters/parameters  [hidden]
    gotFeedback % record whether or not we got feedback from previous trial
                % - TRUE if proper usage of  p.condMatrix.putBack(p);  occurred during [.trialCleanUpandSave] pldaps state
                % - see  modularDemo.pmBase.m  for example
    nModules    % Number of matrix modules in use
    padded      % keep track of conditions added to pad complete trial at tend of pass
    
    nBlocks     % number of unique blocks
    blockParamsLevel  % index to Params Class level containing current block parameters
    
    %  derived/redundant values
    ptr         % PTB window pointer
    pWidth      % pixel width of display
    pHeight     % pixel height of display
    wWidth      % physical width of monitor [cm]
    wHeight     % physical height of monitor [cm]
    ctr         % center point of display [px: x,y]
    frate       % frame rate of monitor [hz]
    ifi         % inter-frame interval [sec]
end


methods
    %% Constructor
    function cm = condMatrix(p, varargin)
        if nargin<1
            error('condMatrix:constructorInput', 'PLDAPS object [p] must be provided during condMatrix creation');
        end
        % If .condMatrix already exists as a struct (i.e. .condMatrix.conditions created during experiment setup),
        % extract the values from it before overwriting it with this condMatrix object.
        if ~isempty(fieldnames(p.condMatrix))
            % Conditions
            if isfield(p.condMatrix, 'conditions')
                % A cell of matrixModule fields defining each condition
                % - conditions limited to fields w/in matrixModule iterations
                % - e.g.   pldapsModule('modName',sn, 'name','modularDemo.pmMatrixGabs', 'matrixModule',true, 'order',10);
                cm.conditions = p.condMatrix.conditions;
            end
            % Blocks
            if isfield(p.condMatrix, 'blocks')
                % -- A cell of fields, like p.conditions
                % -- ...specific enough that a creation method would be best?
                cm.blocks   = p.condMatrix.blocks;
                cm.nBlocks  = numel(cm.blocks);
            else
                cm.blocks	= [];
                cm.nBlocks  = 0;
            end
            
        end
        
        % Parse inputs & setup default parameters
        pp = inputParser();
        % Basic condMatrix parameters
        pp.addParameter('i', 0);
        pp.addParameter('iPass', 0);
        pp.addParameter('nPasses', inf);    
        pp.addParameter('order', []);
        pp.addParameter('passSeed', sum(100*clock));    
        % Control interaciton/execution of condMatrix
        pp.addParameter('randMode', 0);
        pp.addParameter('baseIndex', 1000);
        pp.addParameter('useFrameDurations',false);
        pp.addParameter('iBlock', 0);
        pp.addParameter('blockModulo', 1);

        
        % Do the parsing
        try
            pp.parse(varargin{:});
        catch
            warning('Name-value pair inputs for condMatrix creation could not be parsed')
            keyboard
        end
        argin = pp.Results;
        
        % Apply to condMatrix object
        fn = fieldnames(argin);
        for i = 1:length(fn)
            % add property if non-standard
            if ~isprop(cm,fn{i})
                cm.addprop(fn{i});
            end
            cm.(fn{i}) = argin.(fn{i});
        end
        
        % record of matrix module names
        cm.modNames  = p.trial.pldaps.modNames;
        cm.nModules = numel(cm.modNames.matrixModule);
        cm.padded = false(1,cm.nModules);
        
        % Initialize counter of conditions shown with zeros
        cm.condReps = zeros(size(cm.conditions));
        cm.gotFeedback = false;

        % Error check .randMode
        % - if >2 matrix dimensions, scalar randMode==3 will crash
        %   change to indexed dimensions & warn
        if isscalar(cm.randMode) && cm.randMode==3 && ndims(cm.conditions)>2
            warning('condMatrix:setup', '[condMatrix.randMode]==3 incompatible with >2 dimensions')
        end
        
% % %         % --- Do we need copies of core/static pldaps variables w/in this class?
% % %         cm.ptr       = p.trial.display.ptr;
% % %         
% % %   These don't exist at time of condMatrix initialization.
% % %   ...consider adding a postOpenScreen routine to p.run to update condMatrix,
% % %   but seems like a crufty solution.
% % %   Better off letting condMatrix do one thing well, than all-the-things cryptically
% % % 
% % %         % size of the display (physical measurement & pixel count...not visual degrees)
% % %         cm.wWidth    = p.trial.display.wWidth;
% % %         cm.wHeight   = p.trial.display.wHeight;
% % %         cm.pWidth    = p.trial.display.pWidth;
% % %         cm.pHeight   = p.trial.display.pHeight;
% % %         
% % %         % variables for converting units
% % %         cm.ctr       = p.trial.display.ctr(1:2); % ...ctr should be a point (not a rect) in the first place
% % %         cm.frate     = p.trial.display.frate;
% % %         cm.ifi       = p.trial.display.ifi;
% % %         
    
    end
    
    
    %% nextCond: apply next conditions
    function p = nextCond(cm, p, targetModule)
        % Get next condition index & apply [to specified module, if provided]
        
        if nargin<3 || isempty(targetModule)
            targetModule = cm.modNames.matrixModule;
        end
        
        nModules = numel(targetModule);
        cm.padded = false(1, nModules);
        
        % Apply conditions to targetModule(s) serially
        for i = 1:nModules
            % ensure we don't exceed available indices
            [ii, isNewPass] = getNextCond; % nested function selects next cond, also manage .order & .iPass
            
            if i==1
                % Initialize new trial with only the appropriate 'Params Levels' active
                % - TODO:  replace this params class usage with a 'freshTrial' struct
                if ~strcmpi(class(p.trial), 'params')  % == isa() & ignore case
                    error('condMatrix:nextCond',['!!!\t[p.trial] must be a pointer to the Params Class object in [p.defaultParameters] for this version to work\n',...
                                   '\t(...as would be expected at start of a new trial w/in p.run)']);
                end
                
                % unlock the defaultParameters
                lockState = p.trial.setLock(false);
                                
                if ~isempty(cm.blocks)
                    % Update block params (if present)
                    if isNewPass
                        % increment block counter & update parameters
                        p = cm.nextBlock(p);
                        % -----------------------%
                        p.trial.setLevels( [p.static.pldaps.baseParamsLevels, cm.blockParamsLevel] );
                        
                        % Update display object from p.trial struct
                        % - .viewdist is a speciall case parameter that triggers external updates/dependencies
                        p.static.display.viewdist = p.trial.display.viewdist;
                    else
                        % block already exists, activate it & baseParams
                        p.trial.setLevels( [p.static.pldaps.baseParamsLevels, cm.blockParamsLevel] );
                    end
                    
                else
                    % Only activate baseParamsLevels (No blocks defined in condMatrix)
                    p.trial.setLevels( p.static.pldaps.baseParamsLevels );
                end
            
                % create the new params level for this trial (but don't make it active yet)
                p.trial.addLevels( {struct}, {sprintf('Trial%dParameters', p.trial.pldaps.iTrial)}, false);
                
                % Append new trial level to currently active levels
                % - this will result in either [base + trial] or [base + block + trial] levels active
                p.trial.setLevels( [p.trial.getActiveLevels, length(p.trial.getAllLevels)] );
                
                % NOTE:  p.run will take care of recording the list of active 'Levels' on every trial w/in  [p.data{}.pldaps.activeLevels]

                % return 'lock' state of defaultParameters to inital state
                if lockState
                    p.defaultParameters.setLock(true);
                end
                % Good to go!   (...barrrf)
            end


            % Apply fields of condition [ii] to matrix module [i]
            fn = fieldnames(cm.conditions{ii});
            % cycle through each condition field
            for k = 1:numel(fn)
                p.trial.(targetModule{i}).(fn{k}) = cm.conditions{ii}.(fn{k});
            end
            p.trial.(targetModule{i}).condIndex = ii;
        end
        
        updateInfoFig(cm, p);
        % reset feedback flag
        cm.gotFeedback = false;
        
        % ----------------------
        % % Nested Function % %
        % getNextCond
        function [nextCondI, isNewPass] = getNextCond
            isNewPass = false;
            if cm.i+1 <= numel(cm.order)
                % queue next condition from order
                cm.i = cm.i+1;
                nextCondI = cm.order(cm.i);
            else
                % updateOrder, or pad if necessary
                if i>1
                    % when available conditions are exceeded mid-trial assignment,
                    % pad with random sample of conditions, but don't alter [cm.order] or [cm.i]
                    nextCondI = randperm(numel(cm.conditions),1);
                    cm.padded(i) = true;
                else
                    % ONLY advance to a new 'pass' when:
                    % - ALL conditions of proceeding pass (incl. "putbacks") have been presented
                    % - AND we are at the start of a new trial
                    updateOrder(cm);
                    cm.i = cm.i+1;
                    nextCondI = cm.order(cm.i);
                    isNewPass = true;
                end
            end
        end %getNextCond
        % ----------------------
    
    end %nextCond
    
    
    %% setNextCond
    function setNextCond(cm, nextCondI)
        if length(cm.order)>=cm.i+1
            cm.order = [cm.order(1:cm.i); nextCondI(:); cm.order(cm.i+1:end)];
        else
            cm.order = [cm.order; nextCondI(:)];
        end
        
    end %setNextCond
    
    
    %% putBack: unused conds
    function output = putBack(cm, p, unusedConds)
        if nargin<3
            unusedConds = [];
            for i = 1:length(p.trial.pldaps.modNames.matrixModule)
                mN = p.trial.pldaps.modNames.matrixModule{i};
                theseConds(i) = p.trial.(mN).condIndex;
                wasShown(i) = p.trial.(mN).shown;
                %                 if ~p.trial.(mN).shown
                %                     unusedConds(end+1) = p.trial.(mN).condIndex;
                %                 end
            end
            unusedConds = theseConds(~wasShown & ~cm.padded);
            % don't count conds that were used only as padding to fill out last trial in a pass
            %  ...else broken trials can erroneously drop presentations or runup the order
        end
        
        % Append incomplete condition indices to the end of order list
        cm.order(end+(1:numel(unusedConds))) = unusedConds;
        if any(wasShown<0)
            fprintf(2, '~!~\tWARNING: Incomplete stimulus presentation detected on trial %d.\n', p.trial.trialnumber)
        end

        % increment counter of conditions presented (exclude padding)
        ii = theseConds(wasShown & ~cm.padded);
        cm.condReps(ii) = cm.condReps(ii)+1;
        
        cm.gotFeedback = true;
        
        % Return set of "conditions shown" to caller [if requested]
        if ~nargout
            return
        else
            output = theseConds(logical(wasShown)); %unusedConds;
        end
        
    end %putBack
    
    
    %% updateOrder: Generate new order set
    function updateOrder(cm)
        % Generate new order set with appropriate randomization, increment pass number, and zero out counter index
        % TODO:  smart way to get a few more cond indices when not enough remaining to populate a trial with multiple
        %        matrixModules without fully advancing into another 'pass'
        
        % increment condMatrix pass number
        cm.iPass = cm.iPass + 1;
        % Manage rng state
        rng0 = rng(cm.passSeed + cm.iPass, 'twister');
        
        % Generate new .order set for condition matrix
        sz = size(cm.conditions);
        condDims = max([1, sum(sz>1)]); % workaround for  ndims(scalar)==2 (?!?)
        % Initialize list of condition indexes
        newOrder = reshape(1:numel(cm.conditions), sz);
        
        % Randomize order as requested
        if numel(cm.randMode)>1
            % Randomize BY DIMENSION
            for i = 1:length(cm.randMode) % Should this always also equal condDims?
                if cm.randMode(i)>0
                    % Positive dimension modes use ShuffleMex (see:  PLDAPS/SupportFunctions/ShuffleMex)
                    newOrder = ShuffleMex(newOrder, cm.randMode(i));
                elseif cm.randMode(i)<0
                    % Negative dimension modes shuffle order of that dim, while maintaining order of all others.
                    % This eval solution is scrappy, but it works, and haven't found similar functionality elsewhere --TBC 2018-08
                    ii = abs(cm.randMode(i));
                    eStr = ['newOrder = newOrder(',repmat(':,',1, ii-1), mat2str(randperm(sz(ii))), repmat(',:',1, condDims-ii),');']
                    eval(eStr)
                else
                    % 0 does nothing to that dimension
                end
            end
        else
            switch cm.randMode
                case 1 % randomize across all dimensions
                    newOrder = reshape(Shuffle(newOrder(:)), sz);
                case 2  % randomize within columns
                    newOrder = Shuffle(newOrder);
                case 3  % randomize within rows
                    switch ndims(newOrder)
                        case {1,2}
                            newOrder = Shuffle(newOrder');
                        case 3
                            % Transpose will fail with >2 condDims! ...how to make robust equivalent??
                            for i = randperm(size(newOrder,3))
                                newOrder(:,:,i) = Shuffle(newOrder(:,:,i)');
                            end
                        otherwise
                            error('condMatrix:randMode:dimensionMismatch',...
                                'Cannot use simple randMode==3 with %d dimension matrix.\nTry indexed randModes for desired result instead...',ndims(newOrder));
                            
                    end
                    % newOrder = Shuffle(newOrder');
                otherwise
                    % do nothing
            end
        end
        % Expand order matrix so unused conditions can be 'put back' if necessary
        cm.order = newOrder(:);
        
        % zero out counter index
        cm.i = 0;
        
        % Return rng state to previous
        rng(rng0);
        
    end %updateOrder
    
    
    %% nextBlock: apply next block parameters
    function p = nextBlock(cm, p)
        % Get next block index & apply any block parameters provided
        if ~mod(cm.iBlock, cm.blockModulo)
            % ensure we don't exceed available block indices
            ii = getBlockIndex; % nested function
            
            % % % % Do this once we ditch Params Class:
            % % %             % merge values of this block into [p.trial]  (recursive struct updating)
            % % %             p.trial = setstructfields(p.trial, cm.blocks{ii});
            
            % funky Params class levels to apply block params to p.trial
            % TODO:  Excise this so we aren't leaning on hacky "params levels"
            newBlockLevel = cm.blocks{ii};
            
            % Create the new block level (but don't make it active yet)
            p.defaultParameters.addLevels({newBlockLevel}, {sprintf('block%dParameters', ii)}, false);
            % append this new level to the baseParamsLevels
            cm.blockParamsLevel = length(p.defaultParameters.getAllLevels);
        end
        
        % increment after evaluating (annoyingly '0-based', but makes modulo indexing easier)
        cm.iBlock = cm.iBlock+1;
        
        
        % ----------------------
        % % Nested Function % %
        % getNextCond
        function nextBlockI = getBlockIndex
            % simple modulo since no block randomization yet
            nextBlockI = mod( floor(cm.iBlock/cm.blockModulo), cm.nBlocks)+1;
            
            % ...see getNextCond for random order code when ready
        end %getNextBlock
        % ----------------------
    
    end %nextBlock
    
    
    %% updateInfoFig
    function updateInfoFig(cm, p)
     % Update Info Fig    (This is still SUPER rudimentary, but better than nothing. --TBC)        
        if ishandle(cm.H.infoFig)
            pctRemain = mean(cm.condReps(:)==cm.iPass)*100; %(1-(numel(cm.order)-cm.i) / numel(cm.conditions)) *100;
            
            % trial count text
            cm.H.infoFig.Children(1).Children(end).String = sprintf('Trial:  %5d\nPass:  %5d  (%02.1f%%)', p.trial.pldaps.iTrial, cm.iPass, pctRemain);  % cm.i/numel(cm.order)*100);
            % fixation text
            cm.H.infoFig.Children(1).Children(end-1).String = sprintf('Fix Pos:    %s\nFix Lim:    %s',...
                    mat2str(p.trial.(p.trial.pldaps.modNames.currentFix{1}).fixPos),...
                    mat2str(p.trial.(p.trial.pldaps.modNames.currentFix{1}).fixLim));
            refreshdata(cm.H.infoFig);%.Children(1));
            
        else
            % Info figure
            Hf = figure(cm.baseIndex); clf;
            set(Hf, 'windowstyle','normal', 'toolbar','none', 'menubar','none', 'selectionHighlight','off', 'color',.5*[1 1 1], 'units','normalized');%'position',[1000,100,400,300])
            set(Hf, 'Name', p.trial.session.file, 'NumberTitle','off', 'position', [.8,.02,.18,.2]);
            
            % Axes for text
            ha = axes;
            box off;
            set(ha, 'color',.5*[1 1 1], 'fontsize',10);
            axis(ha, [0 1 0 1]); axis off
            fsz = 12;
            % Basic trial info text
            ht(1) = text(ha, 0, 0.8, sprintf('Trial:  %5d\nPass:  %5d', p.trial.pldaps.iTrial, cm.iPass));
            try
                ht(2) = text(ha, 0, 0.5, sprintf('Fix Pos:    %s\nFix Lim:    %s',...
                    mat2str(p.trial.(p.trial.pldaps.modNames.currentFix{1}).fixPos),...
                    mat2str(p.trial.(p.trial.pldaps.modNames.currentFix{1}).fixLim)));
            end
            set(ht, 'fontsize',fsz);
            
            % only need handle to parent figure to access all contents
            cm.H.infoFig = Hf;
            %             drawnow; % required for figure update on ML>=2018a
            %             refreshdata(cm.H.infoFig);%.Children(1));
        end
        drawnow limitrate;    
        
    end %updateInfoFig

end %methods


end %classdef
