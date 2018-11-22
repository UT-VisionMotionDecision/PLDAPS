classdef pldaps < handle
%pldaps    main class for PLDAPS (Plexon Datapixx PsychToolbox) version 4.2
% The pldaps contructor accepts the following inputs, all are optional, but may be required later for experiments to run:
%     1. a subject identifier (string)
%     2. a function name or handle that sets up all experiement parameters
%     3. a struct with changes to the defaultParameters, this is usefull for debugging, but could also be used to replace the function.
% As long as the inputs are uniquely identifiable, the order is not important, otherwise 
% for the remaining unclassified inputs the above order is assumed.
% Read README.md for a more detailed explanation of the default usage

%% --- Properties ---
 properties
    defaultParameters@params

    conditions@cell %cell array with a struct like defaultParameters that only hold condition specific changes or additions

    condMatrix % machinery for selection & randomization of parameters set by the contents of p.conditions
    
    trial %will get all variables from defaultParameters + correct conditions cell merged. This will get saved automatically. 
          %You can add calculated paraneters to this struct, e.g. the
          %actual eyeposition used for caculating the frame, etc.
    data@cell
    
    functionHandles %mostly unused (...created, but never developed before jk handoff; circa Pldaps 4.2)
 end

 
%% --- Methods ---
 methods
     function p = pldaps(varargin)
         %% setup default parameters
        %classdefaults: create default structure from function
        defaults{1}=pldaps.pldapsClassDefaultParameters();
        defaultsNames{1}='pldapsClassDefaultParameters';
        
        %rigdefaults: load from prefs?
        defaults{2}=getpref('pldaps');
        defaultsNames{2}='pldapsRigPrefs';
        
        p.defaultParameters=params(defaults,defaultsNames);
        
        %DEPRECATED:   Use createRigPrefs.m to update rig prefs framework
        if isField(p.defaultParameters,'pldaps.rigParameters')
            error(['Storing rigPrefs within the .pldaps.rigParameters field is depreciated.\n',...
                    '\tRun createRigPrefs.m to create updated preferences storage inline with PLDAPS ver. 4.2 (and beyond)'], [])
        end
        
        
        %% Process inputs
        %if an input is a struct, this is added to the defaultParameters. 
        %if an input is a cell. this is set as the conditions
        
        %It's contents will override previous parameters
        %the first nonStruct is expected to be the subject's name
        %the second nonStruct is expected to be the experiment functionname
        structIndex=cellfun(@isstruct,varargin);
        if any(structIndex)
            if sum(structIndex)>1
                error('pldaps:pldaps', 'Only one struct allowed as input.');
            end
            constructorStruct=varargin{structIndex};
        else
            constructorStruct=struct;
        end

        cellIndex=cellfun(@iscell,varargin);
        if any(cellIndex)
            if sum(cellIndex)>1
                error('pldaps:pldaps', 'Only one cell allowed as input.');
            end
            p.conditions=varargin{cellIndex};
        end
        
        if nargin>4
            error('pldaps:pldaps', 'Only four inputs allowed for now: subject, experimentSetupFile (String or function handle), a struct of parameters and a cell with a struct of parameters for each trial.');
        end
        subjectSet=false;
        for i=1:nargin
            if isa(varargin{i}, 'function_handle') %fucntion handle will be the experimentSetupFunction
                 constructorStruct.session.experimentSetupFile=func2str(varargin{i});
            elseif isa(varargin{i}, 'string')
                    constructorStruct.session.subject=varargin{i};
                    subjectSet=true;                
            elseif isa(varargin{i}, 'char')
                if ~subjectSet  %set experiment file
                    constructorStruct.session.subject=varargin{i};
                    subjectSet=true;
                else
                    constructorStruct.session.experimentSetupFile=varargin{i};
                end
            end
        end
        constructorStruct.session.caller = dbstack(1, '-completenames');
        p.defaultParameters.addLevels({constructorStruct, struct},{'ConstructorInputDefaults', 'SessionParameters'});
        
        
        % Establish p.trial as a handle to p.defaultParameters        
        p.trial = p.defaultParameters; 
        % Hackish duplication, but standard procedure evolved to basically only use/interact with p.trial.
        % Explicity use of p.defaultParameters only really done in legacy or under-the-hood code now.
        % Also allows the same code that works inside a running session (or inside a module) to be run
        % in the command window [...for the most part].
        
        % Take module inventory
        if p.trial.pldaps.useModularStateFunctions
            % Establish list of all module names
            p.trial.pldaps.modNames.all = getModules(p, 0);
            p.trial.pldaps.modNames.matrixModule = getModules(p, bitset(0,2));
        end

        %% setup condMatrix
        % Moved to condMatrix class definition
        % To use condMatrix, assign typical p.conditions values to p.condMatrix.conditions,
        % then run:
        %       p.condMatrix = condMatrix(p, [...]);
        % where [...] is optional set of name-value pairs. PLDAPS will do the rest.
        % See help condMatrix
        % 
        %
        % % %         % initialize
        % % %         p.condMatrix.i = 0;
        % % %         p.condMatrix.pass.i = 0;
        % % %         p.condMatrix.pass.seed = sum(100*clock); % base rng seed
        % % %         p.condMatrix.pass.end = inf;    % Stop experiment after n-passes
        % % %         p.condMatrix.order = [];    % [randomized] set of condition indexes for current pass
        % % %         p.condMatrix.randMode = [];  % random ordering of conditions selectable by matrix dimension
        % % %         % This is the beta version of randMode. It only acts as a flag for a select
        % % %         %   0 = no randomization;
        % % %         %   1 = across all dims  == reshape(Shuffle(p.conditions{:}), size(p.conditions))
        % % %         %   2 = across columns   == Shuffle(p.conditions))
        % % %         %   3 = across rows      == Shuffle(p.conditions')'
        % % %         %
        % % %         % sized 1-by-nDimensions present in p.conditions cell.
        % % %         % 0 == no randomization
        % % %         % 1:n == order of randomization groupings.
        % % %         % GIVEN:
        % % %         % 	% get number of condition dimensions (excluding singletons that ndims.m counts)
        % % %         % 	condDims = max([1, sum(size(p.conditions)>1)]);
        % % %         % EXAMPLES:	 (if size(p.conditions)==[2,3,6]; condDims = 3;)
        % % %         %
        % % %         % randMode = [0 0 0];	% DEFAULT % zeros(1,condDims);
        % % %         % 	-->>  cycles through condition matrix without randomizing
        % % %         %
        % % %         % randMode = [1 1 1];	% ones(1,condDims);
        % % %         % 	-->>  randomizes across all dimensions
        % % %         %
        % % %         % randMode = [0 1 1];
        % % %         % 	-->>  randomize last two dims together, maintain order of first dim
        % % %         %
        % % %         % randMode = [1 2 3];
        % % %         % 	-->>  randomize each dimension separately.
        % % %         %         Thus each (1,i,:) contains all values of last dim paired with ith value of 2nd dim; order of second dim is randomized.
        % % %         %         Each (1,:,:) contains all combinations of one value of first parameter with all other parameters.   

     end   
 end
 

%% --- Static Methods ---
methods(Static)
    % Status of these conversion functions is unknown, and all display a warning directing users tooward
    % pds.<method> versions instead. For now, I will disable them, & listen for complaints. --TBC Summer 2018
    % % %     [xy,z] = deg2px(p,xy,z,zIsR)
    % % %
    % % %     [xy,z] = deg2world(p,xy,z,zIsR)
    % % %
    % % %     [xy,z] = px2deg(p,xy,z)
    % % %
    % % %     [xy,z] = world2deg(p,xy,z)
    
    [xy,z] = deg2world(p, varargin);%(p,xy,z)
    
    held = checkFixation(varargin)
    
    s = pldapsClassDefaultParameters(s)
    
    [stateValue, stateName] = getReorderedFrameStates(trialStates,moduleRequestedStates)

end

end % classdef