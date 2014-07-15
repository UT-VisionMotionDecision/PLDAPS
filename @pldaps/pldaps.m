classdef pldaps < handle
 properties
    defaultParameters

    conditions %cell array with a struct like defaultParameters that only hold condition specific changes or additions

    trial %will get all variables from defaultParameters + correct conditions cell merged. This will get saved automatically. 
          %You can add calculated paraneters to this struct, e.g. the
          %actual eyeposition used for caculating the frame, etc.
    data
    
    trialFunctionHandle
 end

 methods
    function dv = pldaps(varargin)
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
        
        dv.defaultParameters=params(defaults,defaultsNames);
        
        %unnecassary, but we'll allow to save parameters in a rig
        %struct, rather than the prefs, as that's a little more
        %conveniant
        if isField(dv.defaultParameters,'pldaps.rigParameters')
            defaults{3}=load(dv.defaultParameters.pldaps.rigParameters);
            fn=fieldnames(defaults{3});
            if length(fn)>1
                error('pldaps:pldaps', 'The rig default parameter struct should only have one fieldname');
            end
            defaults{3}=defaults{3}.(fn{1});
            defaultsNames{3}=fn{1};
             
            dv.defaultParameters.addLevels(defaults(3),defaultsNames(3));
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
            dv.conditions=varargin{cellIndex};
        end
        
        if nargin>4
            error('pldaps:pldaps', 'Only four inputs allowed for now: subject, experimentSetupFile (String or function handle), a struct of parameters and a cell with a struct of parameters for each trial.');
        end
        subjectSet=false;
        for iArgin=1:nargin
            if ~isstruct(varargin{iArgin})
                if isa(varargin{iArgin}, 'function_handle') %fucntion handle will be the experimentSetupFunction
                     constructorStruct.session.experimentSetupFile=func2str(varargin{iArgin});
                else
                    if ~subjectSet  %set experiment file
                        constructorStruct.session.subject=varargin{iArgin};
                        subjectSet=true;
                    else
                        constructorStruct.session.experimentSetupFile=varargin{iArgin};
                    end
                end
            end
            
        end       
        dv.defaultParameters.addLevels({constructorStruct, struct},{'ConstructorInputDefaults', 'SessionParameters'});
        
        
        %TODO: decice wheter this is a hack or feature. Allows to use
        %dv.trial before the first trial. But it's a Params class
        %until the first trial starts
        dv.trial = dv.defaultParameters; 
    end 
     
    
 end %methods

 methods(Static)
      [xy,z] = deg2px(dv,xy,z,zIsR)
      
      [xy,z] = deg2world(dv,xy,z,zIsR)
      
      [xy,z] = px2deg(dv,xy,z)
      
      [xy,z] = world2deg(dv,xy,z)
 end

end