classdef condMatrix < dynamicprops
%     handle class (w/dynamic properties) for controlling PLDAPS condition matrix

properties (Access = public)
    conditions % TODO: make this a pointer to p.conditions, or vice-versa?
%     condFields % static list of condition field names
    
    i       % index # of current position in .condMatrix.order
    iPass	% index # of current pass
    nPasses     % end experiment after nPasses through condition matrix
    order   % [randomized]sequence of condition indices for the current pass
    passSeed    % base for random seed:  rng(.passSeed + .iPass, 'twister')
    randMode    % flag for randomization through condition matrix [.condMatrix.conds]
    % Randomize order of upcoming pass through condition matrix based on:
    %         switch cm.randMode
    %             case 1 % randomize across all dimensions
    %                 newOrder = reshape(Shuffle(newOrder(:)), sz);
    %             case 2  % randomize within columns
    %                 newOrder = Shuffle(newOrder);
    %             case 3  % randomize within rows (not good...this will fail with >2 condDims!)
    %                 newOrder = Shuffle(newOrder');
    %             otherwise
    %                 % do nothing
    %         end
    baseIndex   % base index value used to distinguish condition index strobed words, and as matrixModule onset strobe

    modNames    % module names struct
    maxFrames   % max number of frames per trial
end

properties (Access = private, Transient = true)
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
            if isfield(p.condMatrix, 'conditions')
                % ???? How does this need to be structured?
                % -- A cell of fields, like p.conditions
                % -- ...specific enough that a creation method would be best?
                cm.conditions = p.condMatrix.conditions;
                %             % list fieldnames set by conditions matrix
                %             cm.condFields = fieldnames(cm.conditions);
                fprintf(2, '\n\t!!!\tp.condMatrix manually initialized...this is might not be good.\n')
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
        

% % %         % --- Store copies of core/static pldaps variables w/in this class
% % %         cm.ptr       = p.trial.display.ptr;
        cm.modNames  = p.trial.pldaps.modNames;
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
% % %         % individual trial parameters
% % %         cm.maxFrames = p.trial.pldaps.maxTrialLength;

    end
    
    
    %% nextCond: apply next conditions
    % Get next condition index & apply [to specified module, if provided]
    function p = nextCond(cm, p, targetModule)
        % Parse inputs
        %         if nargin>3
        %             putBack(cm, unusedConds);
        %         end
        if nargin<3 || isempty(targetModule)
            targetModule = cm.modNames.matrixModule;
        end
        
        % Apply to targetModule(s) serially, updateOrder if necessary
        for i = 1:numel(targetModule)
            % refresh order if run out of available indexes
            if cm.i+1 > numel(cm.order)
                updateOrder(cm);
            end
            cm.i = cm.i+1;
            ii = cm.order(cm.i);
            fn = fieldnames(cm.conditions{ii}); %cm.condFields;
            % cycle through each condition field
            for k = 1:numel(fn)
                p.trial.(targetModule{i}).(fn{k}) = cm.conditions{ii}.(fn{k});
            end
            p.trial.(targetModule{i}).condIndex = ii;
        end
    end
    
    
    %% putBack: unused conds
    function putBack(cm, unusedConds)
        % Append incomplete condition indexes to the end of order list
        cm.order(end+1:numel(unusedConds)-1) = unusedConds;
    end
    
    
    %% updateOrder: Generate new order set
    function updateOrder(cm)
        % increment condMatrix pass number
        cm.iPass = cm.iPass + 1;
        % Manage rng state
        rng0 = rng(cm.passSeed + cm.iPass, 'twister');
        
        % Generate new .order set for condition matrix
        sz = size(cm.conditions);
        condDims = max([1, sum(sz>1)]);
        % Initialize list if condition indexes
        newOrder = reshape(1:numel(cm.conditions), sz);
        
        % Randomize order as requested
        switch cm.randMode
            case 1 % randomize across all dimensions
                newOrder = reshape(Shuffle(newOrder(:)), sz);
            case 2  % randomize within columns
                newOrder = Shuffle(newOrder);
            case 3  % randomize within rows (not good...this will fail with >2 condDims!)
                newOrder = Shuffle(newOrder');
            otherwise
                % do nothing
        end
        cm.order = newOrder(:);
        
        % zero out counter index
        cm.i = 0;
        
        % Return rng state to previous
        rng(rng0);
    end
    
end


end