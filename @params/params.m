classdef params < handle
%PARAMS    A hierarchical parameter handling class
% PARAMS takes a cell array of strucs and a cell array of names and
% organized it so that you can access a parameter that is defined in any of
% those structs. If a parameter is defined in more than one struct, the
% value of the struct with the higher index is used.
% The hierarchy levels can be limited by calling PARAMS.setLevels.
% New levels can be added using PARAMS.addLevels
% Since performance is not sufficient for high demand scenarios as many
% psychphysical experiments, the paraneters often have to be merged to a
% single struct for use during a trial with PARAMS.mergeToSingleStruct
% Use PARAMS.getDifferenceFromStruct to get a struct that only hold changes
% made to a perviously obtained merged single struct.
% PARAMS.view opens a gui for visualization and editing of the parameters

 
    properties
        structs
        structNames
        activeLevels
        topLevel
                      
        flatStruct
        locked
        
        MethodsList
        
        Snew1
    end
    
    
    methods
        function view(p)
            p.structviewer(p);
        end
        
        function setLock(p,lock)
            p.locked = lock;
        end
        
    end

    %% Hide extraneous methods [overloaded & innerworkings] 
    %   They can still be called directly & will show up in our manual list of methods,
    %   but this way they won't muddle tab completion for actual fields of interest.
    %   (e.g. .disp & .display !!)
    %   ...know what, forget it! Lets just hide them all and see if anyone complains.
    
    methods (Hidden)

        % internal params methods
        function p=params(s,sN,active)
            if nargin<2
            	sN=cellfun(@(x) sprintf('level%i',x),num2cell(1:length(s)),'UniformOutput',false);
            end
            if nargin<3
            	active=true(1,length(s));
            end
            p=addStructs(p,s,sN,active);
            % NOTE: Methods not listed here will not be user-accessible
            %    (...because of way the subsref function is overloaded within the Params class)
            p.MethodsList=sort({'view', 'setLevels','getAllLevels', 'mergeToSingleStruct','getDifferenceFromStruct','addLevels','addStructs','addNewStruct',...
                                'getAllStructs','setLock','getParameter','fieldnames','incrementTrial','getActiveLevels'});
            p.Snew1= substruct('.','structs','{}', {NaN});
        end %params(s,sN)

        % Overload some standard/builtin functions
        function disp(p)
            % Is there really any need to still call the builtin?
            % ...you can't actually manipulate the contents of this class directly
            % builtin('disp',p);
            fprintf('PARAMS class object');
            if p.locked == 1
                fprintf('\t(Locked)\n')
            else
                fprintf('\t(UNlocked)\n')
            end
            fprintf('  [active]\tstructName\n')
            disp([num2cell(p.activeLevels)', p.structNames'])
            
            fprintf('\n\tMethods (public):\n')
            fprintf('\t\t%s\n',p.MethodsList{:});
            
            names=fieldnames(p);
            fprintf('\n\tFieldnames:\n');
            fprintf('\t\t%s\n',names{:});
            fprintf('\n')
        end
        
        % Overload fieldnames retrieval
        function names = fieldnames(p) 
            activeFields=cellfun(@(x) any(ismember(find(p.activeLevels),x)), {p.flatStruct.hierarchyLevels});
            names={p.flatStruct(cellfun(@length,{p.flatStruct(activeFields).parentLevels})==1).identifier};
            names=cellfun(@(x) x(2:end),names,'UniformOutput',false);
        end
        
        % ...another struct tab completion helper
        function names = properties(p) 
            names = fieldnames(p);
        end
        
        function is = isField(p,fieldname)
            if(fieldname(1)~='.')
                fieldname=['.' fieldname];
            end
            
            is = ismember(fieldname,{p.flatStruct.identifier});
        end
           
        
        function p=addStructs(p,s,sN,active)
            if nargin<3
                sN=cellfun(@(x) sprintf('level%i',x),num2cell(1:length(s)),'UniformOutput',false);
            end
            if nargin<4
                active=true(1,length(s));
            elseif length(active)==1
                if(active)
                    active=true(1,length(s));
                else
                    active=false(1,length(s));
                end
            else
                % ensure logical
                active= logical(active);
            end
            
            for iStruct=1:length(s)
                p = addNewStruct(p,s{iStruct},sN{iStruct},active(iStruct));
            end
        end
        
        function p=addLevels(varargin)
            p=addStructs(varargin{:});
        end %p=addLevels(p,s,sN,active)
        
        function p=addNewStruct(p,newStruct,newStructName,makeActive)
           %first get at flat version of that Struct
            iLevel=length(p.structs)+1;
            fs=p.getNextStructLevel(newStruct,{},[]);
            id=cellfun(@(x) sprintf('.%s',x{:}), {fs.parentLevels}, 'UniformOutput', false);   
            [fs.identifier]=deal(id{:});
            [fs.hierarchyLevels]=deal(iLevel);
            
            %now merge with the current masterFlatStruct:
            if(isempty(p.flatStruct))
                p.flatStruct=fs;
            else
                %1: find the ones that are overruled (and newly defined (overruled==0
                %&overrluledPos==0
                [overruled, overruledPos]=ismember({fs.identifier},{p.flatStruct.identifier});
                
                 nFields=length(fs);
                 for iField=1:nFields
                    if(overruled(iField))
                        p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = iLevel; 
                    else
                        p.flatStruct(end+1)=fs(iField);
                    end
                 end
            end
            
            p.structs{end+1} = newStruct;
            p.structNames{end+1} = newStructName;
            p.activeLevels(end+1) = makeActive;
            p.activeLevels = logical(p.activeLevels);
            p.topLevel=find(p.activeLevels, 1, 'last');
        end
                
        %TODO: if we allow dirty structs, we need to cosolidate....(no one knows what this means. --TBC)
        function p = setLevels(p,value)
            if islogical(value)
                if length(value)==length(p.structs) 
                    p.activeLevels=value;
                end
            elseif length(value)<length(p.structs)+1 && max(value)<=length(p.structs)
                p.activeLevels(:)=false;
                p.activeLevels(value)=true;
            end          
            p.topLevel=find(p.activeLevels, 1, 'last');
        end
        
        % Return index(s) of currently active params hierarchy levels
        function activeLevels = getActiveLevels(p)
            activeLevels = find(p.activeLevels);
        end
        
        function l = getAllLevels(p)
            l=1:length(p.structs);
        end
        
        function [s, sN, active] = getAllStructs(p)
            s=p.structs;
            sN=p.structNames;
            active=p.activeLevels;
        end
        
        function p = addField(p,id,value,iLevel) 
            %most ineficient way ever: but we are not planning on running
            %this during a trial (for now)
            if nargin<4
                iLevel=p.topLevel;
            end
            
            parentLevels=textscan(id,'%s','delimiter','.');
            parentLevels=parentLevels{1}(2:end);
            %assign the value, could probably use subsref of struct
            %instead.
            Spartial=p.Snew1(ones(1,length(parentLevels)));
            [Spartial.subs]=deal(parentLevels{:});
            S=[p.Snew1 Spartial];
            S(2).subs={iLevel};
            [~]=builtin('subsasgn',p,S,value);
            
            if isstruct(value) %need to flatten that.
                addFlatStruct=p.getNextStructLevel(tmp,parentLevels,[]);
                id=cellfun(@(x) sprintf('.%s',x{:}), {addFlatStruct.parentLevels}, 'UniformOutput', false);   
                [addFlatStruct.identifier]=deal(id{:});
                [addFlatStruct.hierarchyLevels]=iLevel;
            
                [overruled, overruledPos]=ismember({addFlatStruct.identifier},{p.flatStruct.identifier});
                
                nFields=length(addFlatStruct);
                for iField=1:nFields
                    if overruled(iField)
                        if ~any(p.flatStruct(overruledPos(iField)).hierarchyLevels==iLevel) 
                            p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = iLevel; 
                        end
                    else
                        p.flatStruct(end+1)=addFlatStruct(iField);
                    end
                end
                
            else %simpler...but maybe not worth it
                [overruled, overruledPos]=ismember(id,{p.flatStruct.identifier});
                if overruled 
                    if ~any(p.flatStruct(overruledPos).hierarchyLevels==iLevel) 
                        p.flatStruct(overruledPos).hierarchyLevels(end+1)=iLevel;
                    end
                else
                    addFlatStruct.parentLevels=textscan(id,'%s','delimiter','.');
                    addFlatStruct.parentLevels=addFlatStruct.parentLevels{1}(2:end);
                    
                    addFlatStruct.isNode=false;
                    addFlatStruct.identifier=id;
                    addFlatStruct.hierarchyLevels=iLevel;
                    p.flatStruct(end+1) = addFlatStruct;
                end                
            end
        end
        
        function varargout =getParameter(p,id,iLevel)
            parentLevels=textscan(id,'%s','delimiter','.');
            parentLevels=parentLevels{1}(2:end);

            Spartial=p.Snew1(ones(1,length(parentLevels)));
            [Spartial.subs]=deal(parentLevels{:});

            if nargin<3 %from the merged dataset
                [varargout{1:nargout}] = subsref(p,Spartial);
            else
                S=[p.Snew1 Spartial];
                S(2).subs={iLevel};
                [varargout{1:nargout}] = builtin('subsref',p, S);
            end
        end
                
        function varargout = subsref(p,S)
            if(p.locked)
                if ~strcmp(S(1).type,'.') || ~strcmp(S(1).subs,'setLock')
                   error('params:subsref','params class was locked using setLock(true). Unlock by calling setLock(false) first'); 
                end   
            end
            
            switch S(1).type
                case '.'
                   if any(strcmp(S(1).subs,p.MethodsList))
                        % Enable dot notation for some functions
                        if(nargout==0)
                            builtin('subsref',p,S);
                        else   
                            [varargout{1:nargout}] = builtin('subsref',p,S);%p.(S.subs);  
                        end
                   else
                        dotNr=find(diff(strcmp({S.type}, '.'))==-1);
                        if isempty(dotNr) % no -1, means only '.' in there
                            dotNr=length(S);
                            allDots=true;
                        else
                            allDots=false;
                        end
                        k={S(1:dotNr).type; S(1:dotNr).subs};
                        id=[k{:}];
                        
                        parts_inds=find(strncmp({p.flatStruct.identifier},id,length(id)));
                        length_ids=cellfun(@length,{p.flatStruct(parts_inds).identifier})==length(id);
                        length_ids(~length_ids)=cellfun(@(x) x(length(id)+1)=='.',{p.flatStruct(parts_inds(~length_ids)).identifier});
                        parts_inds=parts_inds(length_ids);
                        
                        levels={p.flatStruct(parts_inds).hierarchyLevels};
                        alevels=cellfun(@(x) any(x(p.activeLevels(x))),levels);
                        
                        levels=levels(alevels);
                        parts_inds=parts_inds(alevels);
                        
                        level_index=cellfun(@(x) max(x(p.activeLevels(x))),levels);
                        nodes=[p.flatStruct(parts_inds).isNode];
                        
                        % if not all Dots, we know the requested data is not
                        % substruct
                        Snew=[p.Snew1 S];
                        if ~allDots || length(parts_inds)==1
                            Snew(2).subs={level_index};
                            [varargout{1:nargout}] = builtin('subsref',p, Snew);
                        else
                            %now if it's a struct, we at least know that
                            %only one output argument is requested, but we
                            %need to mix the struct from all levels
                            try
                                %first assign the whole substruct from the
                                %lowest
                                %level that defined it?
                                min_level=min(level_index);
                                Snew(2).subs={min_level};
                                tmp=builtin('subsref',p, Snew);
                                
                                covered_inds=level_index==min_level;
                                parts_inds(covered_inds | nodes)=[];
                                level_index(covered_inds| nodes)=[];
                                
                                %now loop over the remaining ones...
                                for iPart=1:length(parts_inds)
                                    thisSubID=p.flatStruct(parts_inds(iPart)).parentLevels(length(S)+1:end);
                                    Spartial=S(ones(1,length(thisSubID)));
                                    [Spartial.subs]=deal(thisSubID{:});
                                    
                                    Snew(2).subs={level_index(iPart)};
                                    tmp=builtin('subsasgn',tmp,Spartial,builtin('subsref',p,[Snew Spartial]));
                                end
                                varargout{1}=tmp;
                            catch
                                % Still ambiguous, but better than maddeningly perpetual "subsref" errors
                                jnk = {S.type; S.subs}; jnk = [jnk{:}];
                                warning('Requested params field  %s  is inaccessible or does not exist.', jnk)
                            end
                        end

                   end
                otherwise
                    error('params:subsref', 'just don''t, ok? I''m a params class, so don''t go all brackety on me. Understood? I''m not an array, nor a cell. Is that explicit enough?');
            end
        end

        
        % Increment iTrial value in the "session" level of p.structs{4}.pldaps.iTrial
        % Currently a necessary evil to prevent reinitialization of the trial
        % index from the initial params struct heirarchy levels. Would be nice to
        % integrate assignment of p.conditions & add/set levels calls here, but 
        % too many dependent vars in the p.run workspace to do this cleanly. --TBC 2017-10
        %   (totally cryptic...nothing I can do about it at this point)
        function varargout = incrementTrial(p, delta)
            %   NOTE: [delta] input is increment, not actual value.
            sessionIndex = strcmp(p.structNames, 'SessionParameters');
            p.structs{sessionIndex}.pldaps.iTrial = p.structs{sessionIndex}.pldaps.iTrial + delta;
            if nargout
                varargout{1} = p.structs{sessionIndex}.pldaps.iTrial;
            end
        end
        
        %because all external calls end up here, this makes all properties
        %protected from changes.
        function p = subsasgn(p,S,value)
            %copying a class, but its a handle class,i.e. we expect it to
            %be just the handle
            if isempty(S) && isa(p,'params')
                %% 
                return;
            end
            
            if(p.locked)
                error('params:subsasgn','params class was locked using setLock(true). Unlock by calling setLock(false) first'); 
            end
            
            switch S(1).type
             % Use the built-in subsasagn for dot notation
                case '.'
                    % get a value from the flatStruct
                    %how many .?
                    dotNr=find(diff(strcmp({S.type}, '.'))==-1);
                    if isempty(dotNr) % no -1, meanst only '.' in there
                        dotNr=length(S);
                        allDots=true;
                    else
                        allDots=false;
                    end
                    id=sprintf('.%s',S(1:dotNr).subs);                 
                    
                    [isField, fieldPos]=ismember(id,{p.flatStruct.identifier});
                    
                    Snew=[p.Snew1 S];
                    Snew(2).subs={p.topLevel};
                    
                    if(isField)
                        if(~allDots)
                            %partially changing an existing field, make
                            %sure it exists in this level
                            
                            levels=p.flatStruct(fieldPos).hierarchyLevels(p.activeLevels(p.flatStruct(fieldPos).hierarchyLevels));
                            level_index=max(levels); 
                            if level_index~=p.topLevel
                                Sold=Snew;
                                Sold(2).subs={level_index};
                                
                                [~]=builtin('subsasgn',p,Snew(1:(length(p.Snew1)+dotNr)),builtin('subsref',p,Sold(1:(length(p.Snew1)+dotNr))));
                            end
                        end
                    end
                    [~]=builtin('subsasgn',p,Snew,value);
                    
                    %ok, set the value, now make sure its in the flatStruct
                    if isField
                        parentLevels=p.flatStruct(fieldPos).parentLevels;
                    else
                        parentLevels= {S(1:dotNr).subs};
                    end
                    addFlatStruct=p.getNextStructLevel(value,parentLevels,[]);
                    %finally go back through the initial paranetLevels and
                    %make sure that the node entries exist. not strictly
                    %necessary but good for the viewer
                    for iNode=1:length(parentLevels)-1
                        tmp=struct;
                        tmp.parentLevels=parentLevels(1:iNode);
                        tmp.isNode=true;
                        addFlatStruct(end+1)=tmp; %#ok<AGROW>
                    end
                    
                    
                    id=cellfun(@(x) sprintf('.%s',x{:}), {addFlatStruct.parentLevels}, 'UniformOutput', false);   
                    [addFlatStruct.identifier]=deal(id{:});
                    [addFlatStruct.hierarchyLevels]=deal(p.topLevel);


                    [overruled, overruledPos]=ismember({addFlatStruct.identifier},{p.flatStruct.identifier});

                    nFields=length(addFlatStruct);
                    for iField=1:nFields
                        if overruled(iField) 
                            if ~any(p.flatStruct(overruledPos(iField)).hierarchyLevels==p.topLevel) 
                                p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = p.topLevel; 
                            end
                        else
                            p.flatStruct(end+1)=addFlatStruct(iField);
                        end
                    end

                
                otherwise
                    error('params:subsassign', 'just don''t, ok? I''m a params clas, so don''t go all brackety on me. Understood? I''m not an array, nor a cell. Is that explicit enough?');
            end
                    
        end
            
        %ok now generate the output
        %merged struct: the struct as it's shown in the hierarical viewer
        function mergedStruct=mergeToSingleStruct(p)  
            mergedStruct=struct;
            nFields=length(p.flatStruct);
            for iField=1:nFields
                levels=p.flatStruct(iField).hierarchyLevels(p.activeLevels(p.flatStruct(iField).hierarchyLevels));
                level_index=max(levels(p.activeLevels(levels))); 
                
                if isempty(level_index) ||  p.flatStruct(iField).isNode %not defined in any _active_ levels
                    continue;
                end

                thisSubID=p.flatStruct(iField).parentLevels;
                Spartial=p.Snew1(ones(1,length(thisSubID)));
                [Spartial.subs]=deal(thisSubID{:});
                S=[p.Snew1 Spartial];
                S(2).subs={level_index};
                
                mergedStruct=builtin('subsasgn',mergedStruct,Spartial,builtin('subsref',p,S));
            end
            
        end %mergedStruct=mergeToSingleStruct(p)  

        %return the differerence of a struct to this classes active version
        function dStruct = getDifferenceFromStruct(p,newStruct)
            newFlatStruct=p.getNextStructLevel(newStruct,{},[]);
            newFlatStruct(1).parentLevels={''};
            id=cellfun(@(x) sprintf('.%s',x{:}), {newFlatStruct.parentLevels}, 'UniformOutput', false);   
            [newFlatStruct.identifier]=deal(id{:});
            
            
            activeFields=cellfun(@(x) any(ismember(x,find(p.activeLevels))),{p.flatStruct.hierarchyLevels});
            %we will not handle the possibility newStruct is missing a fieled
            removedFields=~ismember({p.flatStruct(activeFields).identifier},id);
            if any(removedFields)
                warning('params:getDifferenceFromStruct','The newStruct is missing fields the class has.');
            end
            
            [newFields, newFieldPos]=ismember(id,{p.flatStruct.identifier});
            newFields=~newFields;
            newFields([newFlatStruct.isNode])=false;
            
            subs=cell(1,length(newFlatStruct));
            
            nFields=length(newFlatStruct);
            for iField=1:nFields
                if newFields(iField) || newFlatStruct(iField).isNode
                    continue;
                end
                
                fS_index=newFieldPos(iField);
                levels=p.flatStruct(fS_index).hierarchyLevels(p.activeLevels(p.flatStruct(fS_index).hierarchyLevels));
                level_index=max(levels(p.activeLevels(levels))); 
                
                
                if isempty(level_index) %not defined in any _active_ levels
                    newFields(iField) = true;
                else
                    thisSubID=newFlatStruct(iField).parentLevels;
                    Spartial=p.Snew1(ones(1,length(thisSubID)));
                    [Spartial.subs]=deal(thisSubID{:});
                    S=[p.Snew1 Spartial];
                    S(2).subs={level_index};
                    
                    subs{iField}=Spartial;
                    
                    newValue=builtin('subsref',newStruct,Spartial);
                    oldValue=builtin('subsref',p,S);

                    newFields(iField) = ~(strcmp(class(newValue),class(oldValue)) && isequal(newValue,oldValue));
                end
            end
            
            dStruct=struct;          
            for iField=1:nFields
                if newFields(iField)
                    if(isempty(subs{iField}))
                        thisSubID=newFlatStruct(iField).parentLevels;
                        Spartial=p.Snew1(ones(1,length(thisSubID)));
                        [Spartial.subs]=deal(thisSubID{:});
                        subs{iField}=Spartial;
                    end
                    
                    dStruct=builtin('subsasgn',dStruct,subs{iField},builtin('subsref',newStruct,subs{iField}));
                 end
            end
            
        end %dStruct = getDifferenceFromStruct(p,newStruct)
        
        
    end %methods
    
    
    methods(Static, Hidden)
        function vs=valueString(value)
            if isstruct(value)
                vs=[];
            else
                vs=evalc('disp(value)');
                vs=strtrim(vs);
                if ischar(value)
                    vs = ['''' vs '''' ];
                elseif islogical(value)
                    if value
                        vs = 'true';
                    else
                        vs = 'false';
                    end
                elseif iscell(value)
                    vs = ['{' vs '}'];
                elseif ~isempty(value)
                    if length(value)>1
                        vs = [ '[ ' vs ' ]' ];
                    else
                        vs = vs;
                    end
                else
                     vs = '[ ]';
                end
                vs=strtrim(vs);
            end
        end %valueString(value)
        
        function result=getNextStructLevel(s,parentLevels,result)
            if isstruct(s) && length(s)<2
                r.parentLevels=parentLevels;
                r.isNode=true;
                if isempty(result)
                    result=r;
                else
                    result(end+1)=r;
                end

                fn=fieldnames(s);
                nFields=length(fn);
                for iField=1:nFields
                    lev=parentLevels;
                    lev(end+1)=fn(iField); %#ok<AGROW>
                    result=params.getNextStructLevel(s.(fn{iField}),lev,result);
                end
            else %leaf
                r.parentLevels=parentLevels;
                r.isNode=false;
                if isempty(result)
                    result=r;
                else
                    result(end+1)=r;
                end
            end
        end %result=getNextStructLevel(s,parentLevels,result)
        
        varargout = structviewer(varargin)
        
    end %methods(Static)
end