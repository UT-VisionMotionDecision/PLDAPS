classdef pldaps < handle
%pldaps    main class for PLDAPS (Plexon Datapixx PsychToolbox) version 4.1
% The pldaps contructor accepts the following inputs, all are optional, but may be required later for experiments to run:
%     1. a subject identifier (string)
%     2. a function name or handle that sets up all experiement parameters
%     3. a struct with changes to the defaultParameters, this is usefull for debugging, but could also be used to replace the function.
% As long as the inputs are uniquely identifiable, the order is not important, otherwise 
% for the remaining unclassified inputs the above order is assumed.
% Read README.md for a more detailed explanation of the default usage


 properties
    defaultParameters@params

    conditions@cell %cell array with a struct like defaultParameters that only hold condition specific changes or additions

    trial %will get all variables from defaultParameters + correct conditions cell merged. This will get saved automatically. 
          %You can add calculated paraneters to this struct, e.g. the
          %actual eyeposition used for caculating the frame, etc.
    data@cell
    
    functionHandles%@cell %mostly unused atm
 end

 methods
     function p = pldaps(varargin)
        %classdefaults: load from structure
        defaults{1}=load('pldaps/pldapsClassDefaultParameters');
        fn=fieldnames(defaults{1});
        if length(fn)>1
             error('pldaps:pldaps', 'The classes internal default parameter struct should only have one fieldname');
        end
        defaults{1}=defaults{1}.(fn{1});
        defaultsNames{1}=fn{1};
        
        %rigdefaults: load from prefs?
        defaults{2}=getpref('pldaps');
        defaultsNames{2}='pldapsRigPrefs';
        
        p.defaultParameters=params(defaults,defaultsNames);
        
        %unnecassary, but we'll allow to save parameters in a rig
        %struct, rather than the prefs, as that's a little more
        %conveniant
        if isField(p.defaultParameters,'pldaps.rigParameters')
            defaults{3}=load(p.defaultParameters.pldaps.rigParameters);
            fn=fieldnames(defaults{3});
            if length(fn)>1
                error('pldaps:pldaps', 'The rig default parameter struct should only have one fieldname');
            end
            defaults{3}=defaults{3}.(fn{1});
            defaultsNames{3}=fn{1};
             
            p.defaultParameters.addLevels(defaults(3),defaultsNames(3));
        end
        
        
        %handle input to the constructor
        %if an input is a struct, this is added to the defaultParameters. 
        %if an input is a cell. this is set as the conditions
        
        %It's contents will overrule previous parameters
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
        for iArgin=1:nargin
            if isa(varargin{iArgin}, 'function_handle') %fucntion handle will be the experimentSetupFunction
                 constructorStruct.session.experimentSetupFile=func2str(varargin{iArgin});
            elseif isa(varargin{iArgin}, 'char')
                if ~subjectSet  %set experiment file
                    constructorStruct.session.subject=varargin{iArgin};
                    subjectSet=true;
                else
                    constructorStruct.session.experimentSetupFile=varargin{iArgin};
                end
            end
        end
        p.defaultParameters.addLevels({constructorStruct, struct},{'ConstructorInputDefaults', 'SessionParameters'});
        
        
        %TODO: decice wheter this is a hack or feature. Allows to use
        %dv.trial before the first trial. But it's a Params class
        %until the first trial starts
        p.trial = p.defaultParameters; 
    end 
     
    
 end %methods

 methods(Static)
      [xy,z] = deg2px(p,xy,z,zIsR)
      
      [xy,z] = deg2world(p,xy,z,zIsR)
      
      [xy,z] = px2deg(p,xy,z)
      
      [xy,z] = world2deg(p,xy,z)
 end

end