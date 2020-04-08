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
        function structviewerHandle = view(p)
            structviewerHandle = p.structviewer(p);
        end
        
        function prevState = setLock(p,lock)
            prevState = p.locked;
            p.locked = lock;
        end
        
    end

    %% Hide extraneous methods [overloaded & innerworkings] 
    %   They can still be called directly & will show up in our manual list of methods,
    %   but this way they won't muddle tab completion for actual fields of interest.
    %   (e.g. .disp & .display !!)
    %   ...know what, forget it! Lets just hide them all and see if anyone complains.
    
    methods (Hidden)

        %% Constructor
        function p = params(s,sN,active)
            if nargin<2
            	sN=cellfun(@(x) sprintf('level%i',x),num2cell(1:length(s)),'UniformOutput',false);
            end
            if nargin<3
            	active=true(1,length(s));
            end
            % build the hierarchy
            p.addStructs(s,sN,active);
            % NOTE: Methods not listed here will not be user-accessible
            %    (...because of way the subsref function is overloaded within the Params class)
            p.MethodsList = sort({'view', 'setLevels','getAllLevels', 'mergeToSingleStruct','getDifferenceFromStruct','addLevels','addStructs','addNewStruct',...
                                'getAllStructs','setLock','getParameter','fieldnames','incrementTrial','getActiveLevels'});
            
            p.Snew1= substruct('.','structs','{}', {NaN});  % double-ewe tee eff!?!
        end %end params

        %% Overload standard/builtin fxns
        % display only accessable/rational contents of pldaps struct
        function disp(p)
            fprintf('PARAMS class object');
            if p.locked == 1
                fprintf(2, '\t(Locked)\n')
            else
                fprintf('\t(UNlocked)\n')
            end
            if numel(p.activeLevels)>10
                fprintf('  [active]\tstructName\t\t(...& %d inactive levels)\n', sum((p.activeLevels==1)))
                disp([num2cell(p.activeLevels(p.activeLevels==1))', p.structNames(p.activeLevels==1)'])
            else
                fprintf('  [active]\tstructName\n')
                disp([num2cell(p.activeLevels)', p.structNames'])
            end
            % list methods
            jnk = cell(4,4);
            jnk(1:length(p.MethodsList)) = p.MethodsList(:);
            fprintf('\n--Methods (public):\n')
            disp(jnk);
            % list fields/module names
            names=fieldnames(p);
            jnk = cell(ceil(numel(names)/5), 5);
            jnk(1:numel(names)) = names;
            fprintf('\n--Fieldnames:\n');
            disp(jnk)
            fprintf('\n')
        end
        
        % fieldnames from active hierarchy
        function names = fieldnames(p) 
            activeFields=cellfun(@(x) any(ismember(find(p.activeLevels),x)), {p.flatStruct.hierarchyLevels});
            names={p.flatStruct(cellfun(@length,{p.flatStruct(activeFields).parentLevels})==1).identifier};
            names=cellfun(@(x) x(2:end),names,'UniformOutput',false);
        end
        
        % tab completion helper
        function names = properties(p) 
            names = fieldnames(p);
        end
        
        %% isField(p, fieldname) --yuck!!
        function is = isField(p,fieldname)
            if(fieldname(1)~='.')
                fieldname=['.' fieldname];
            end
            is = ismember(fieldname,{p.flatStruct.identifier});
        end
           
        %% addStructs(p, struct, newName, makeActive)
        function addStructs(p,s,sN,active)
            if nargin<3
                % generate default level name
                sN=cellfun(@(x) sprintf('level%i',x),num2cell(1:length(s)),'UniformOutput',false);
            end
            if nargin<4
                % make new level(s) active by default
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
                p.addNewStruct(s{iStruct}, sN{iStruct}, active(iStruct));
            end
        end
        
        %% addLevels --> addStructs(p, struct, newName, makeActive)
        function addLevels(varargin)
            addStructs(varargin{:});
        end %p=addLevels(p,s,sN,active)
        
        %% addNewStruct(p, inputStruct, newStructName, makeActive)
        function addNewStruct(p, inputStruct, newStructName, makeActive)
           %first get flat version of Struct to be added [inputStruct-->inputFlat]
            iLevel = length(p.structs)+1;
            inputFlat = p.getNextStructLevel(inputStruct, {}, []);
            % generate string label for every field & subfield of inputStruct
            id = cellfun(@(x) sprintf('.%s',x{:}), {inputFlat.parentLevels}, 'UniformOutput', false);   
            [inputFlat.identifier] = deal(id{:});
            [inputFlat.hierarchyLevels] = deal(iLevel);
            
            % merge with the existing flatStruct
            if ~isempty(p.flatStruct)
                % find fields that are overruled or newly defined (overruled==0 & overrluledPos==0)
                [overruled, overruledPos] = ismember({inputFlat.identifier}, {p.flatStruct.identifier});
                
                for i = 1:length(inputFlat)
                    if overruled(i)
                        p.flatStruct(overruledPos(i)).hierarchyLevels(end+1) = iLevel;
                    else
                        p.flatStruct(end+1) = inputFlat(i);
                    end
                end
            else
                % First time called, create it!
                p.flatStruct = inputFlat;
            end
            
            p.structs{end+1} = inputStruct;
            p.structNames{end+1} = newStructName;
            p.activeLevels(end+1) = makeActive;
            p.activeLevels = logical(p.activeLevels);
            p.topLevel = find(p.activeLevels, 1, 'last');
        end
                
        %% setLevels(p, value)
        function setLevels(p,value)
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
        
        %% getActiveLevels(p)
        % Return index(s) of currently active params hierarchy levels
        function activeLevels = getActiveLevels(p)
            activeLevels = find(p.activeLevels);
        end
        
        %% getAllLevels(p)
        function l = getAllLevels(p)
            l=1:length(p.structs);
        end
        
        %% getAllStructs(p)
        % output raw contents of a Params hierarchy (...not for mere mortals)
        function [s, sN, active] = getAllStructs(p)
            s = p.structs;
            sN = p.structNames;
            active = p.activeLevels;
        end
        
        %% addField(p, id, value, [iLevel])
        function addField(p,id,value,iLevel) 
            %most ineficient way ever: but we are not planning on running
            %this during a trial (for now)
            if nargin<4
                iLevel = p.topLevel;
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
                
                for i = 1:length(addFlatStruct)
                    if overruled(i)
                        if ~any(p.flatStruct(overruledPos(i)).hierarchyLevels==iLevel) 
                            p.flatStruct(overruledPos(i)).hierarchyLevels(end+1) = iLevel; 
                        end
                    else
                        p.flatStruct(end+1)=addFlatStruct(i);
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
        
        %% getParameter(p, id, [iLevel])
        function varargout = getParameter(p,id,iLevel)
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
                
        %% subsref(p, S)
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
                        isDot = strcmp({S.type}, '.');
                        allDots = all(isDot);
                        isDot = find(isDot);

                        k={S(isDot).type; S(isDot).subs};
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

        %% incrementTrial(p, [delta])
        % Increment iTrial value in the "session" level of p.structs{4}.pldaps.iTrial
        % Currently a necessary evil to prevent reinitialization of the trial
        % index from the initial params struct heirarchy levels. Would be nice to
        % integrate assignment of p.conditions & add/set levels calls here, but 
        % too many dependent vars in the p.run workspace to do this cleanly. --TBC 2017-10
        %   (totally cryptic...nothing I can do about it at this point)
        function varargout = incrementTrial(p, delta)
            %   NOTE: [delta] input is increment, not actual value.
            if nargin<2
                delta = 1;
            end
            sessionIndex = strcmp(p.structNames, 'SessionParameters');
            p.structs{sessionIndex}.pldaps.iTrial = p.structs{sessionIndex}.pldaps.iTrial + delta;
            if nargout
                varargout{1} = p.structs{sessionIndex}.pldaps.iTrial;
            end
        end
        
        %% subsasgn 
        function p = subsasgn(p,S,value)
            % If no indexing provided, just return handle to this params class
            if isempty(S) && isa(p,'params') 
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
                    
                    [fieldExists, fieldPos]=ismember(id,{p.flatStruct.identifier});
                    
                    Snew=[p.Snew1 S];
                    Snew(2).subs={p.topLevel};
                    
                    if fieldExists
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
                    if fieldExists
                        parentLevels=p.flatStruct(fieldPos).parentLevels;
                    else
                        parentLevels= {S(1:dotNr).subs};
                    end
                    addFlatStruct=p.getNextStructLevel(value,parentLevels,[]);
                    %finally go back through the initial parentLevels and
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

                    for i = 1:length(addFlatStruct)
                        if overruled(i) 
                            if ~any(p.flatStruct(overruledPos(i)).hierarchyLevels==p.topLevel) 
                                p.flatStruct(overruledPos(i)).hierarchyLevels(end+1) = p.topLevel; 
                            end
                        else
                            p.flatStruct(end+1)=addFlatStruct(i);
                        end
                    end

                
                otherwise
                    error('params:subsassign', 'Params class referencing error: check fieldname/indexing into p.trial.<....>\n');
            end
                    
        end
            
        
        %% mergeToSingleStruct(p)
        % flatten active params hierarchy into a standard struct
        function mergedStruct=mergeToSingleStruct(p)  
            mergedStruct=struct;

            for i = 1:length(p.flatStruct)
                levels=p.flatStruct(i).hierarchyLevels(p.activeLevels(p.flatStruct(i).hierarchyLevels));
                level_index=max(levels(p.activeLevels(levels))); 
                
                if isempty(level_index) ||  p.flatStruct(i).isNode %not defined in any _active_ levels
                    continue;
                end

                thisSubID=p.flatStruct(i).parentLevels;
                Spartial=p.Snew1(ones(1,length(thisSubID)));
                [Spartial.subs]=deal(thisSubID{:});
                S=[p.Snew1 Spartial];
                S(2).subs={level_index};
                
                mergedStruct=builtin('subsasgn',mergedStruct,Spartial,builtin('subsref',p,S));
            end
            
        end %mergedStruct=mergeToSingleStruct(p)  

        %% getDifferenceFromStruct(p, newStruct, [theseLevels])
        % compare params hierarchy with newStruct & return difference as a single struct
        % (...used to detect fields that were changed during trial & should be saved)
        function dStruct = getDifferenceFromStruct(p, newStruct, theseLevels)
            % allow comparison to an alternate set of activeLevels
            oldLevels = p.activeLevels;
            if nargin>2
                % clunky indexing flip-flop, but it works...
                p.setLevels(theseLevels);
            end
            
            newFlatStruct = p.getNextStructLevel(newStruct, {}, []);
            newFlatStruct(1).parentLevels = {''};
            id=cellfun(@(x) sprintf('.%s',x{:}), {newFlatStruct.parentLevels}, 'UniformOutput', false);   
            [newFlatStruct.identifier]=deal(id{:});
            
            activeFields=cellfun(@(x) any(ismember(x,find(p.activeLevels))),{p.flatStruct.hierarchyLevels});
            %we will not handle the possibility newStruct is missing a field
            removedFields=~ismember({p.flatStruct(activeFields).identifier},id);
            if any(removedFields)
                warning('params:getDifferenceFromStruct','The newStruct is missing fields the class has.');
            end
            
            [newFields, newFieldPos]=ismember(id, {p.flatStruct.identifier});
            newFields=~newFields;
            newFields([newFlatStruct.isNode])=false;
            
            subs=cell(1,length(newFlatStruct));
            
            for i = 1:length(newFlatStruct)
                if newFields(i) || newFlatStruct(i).isNode
                    continue;
                end
                
                fS_index=newFieldPos(i);
                levels=p.flatStruct(fS_index).hierarchyLevels(p.activeLevels(p.flatStruct(fS_index).hierarchyLevels));
                level_index=max(levels(p.activeLevels(levels))); 
                
                
                if isempty(level_index) %not defined in any _active_ levels
                    newFields(i) = true;
                else
                    thisSubID=newFlatStruct(i).parentLevels;
                    Spartial=p.Snew1(ones(1,length(thisSubID)));
                    [Spartial.subs]=deal(thisSubID{:});
                    S=[p.Snew1 Spartial];
                    S(2).subs={level_index};
                    
                    subs{i}=Spartial;
                    
                    newValue=builtin('subsref',newStruct,Spartial);
                    oldValue=builtin('subsref',p,S);

                    newFields(i) = ~(strcmp(class(newValue),class(oldValue)) && isequal(newValue,oldValue));
                end
            end
            
            % build output struct
            dStruct=struct;          
            for i = 1:length(newFlatStruct)
                if newFields(i)
                    if(isempty(subs{i}))
                        thisSubID=newFlatStruct(i).parentLevels;
                        Spartial=p.Snew1(ones(1,length(thisSubID)));
                        [Spartial.subs]=deal(thisSubID{:});
                        subs{i}=Spartial;
                    end
                    
                    dStruct=builtin('subsasgn',dStruct,subs{i},builtin('subsref',newStruct,subs{i}));
                 end
            end
            
            % Return previous activeLevels state
            p.setLevels(oldLevels);
        end
        
        
    end %methods
    
    
    methods(Static, Hidden)
        % ...what is this wart?
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
        
        %% getNextStructLevel
        function result = getNextStructLevel(s, parentLevels, result)
            if isstruct(s) && length(s)<2 % a node
                r.parentLevels = parentLevels;
                r.isNode = true;
                if isempty(result)
                    result = r;
                else
                    result(end+1) = r;
                end

                fn = fieldnames(s);
                for i = 1:length(fn)
                    lev = parentLevels;
                    lev(end+1) = fn(i); %#ok<AGROW>
                    result = params.getNextStructLevel(s.(fn{i}), lev, result);
                end                
            else %leaf (~node)
                r.parentLevels = parentLevels;
                r.isNode = false;
                if isempty(result)
                    result = r;
                else
                    result(end+1) = r;
                end
            end
        end %result=getNextStructLevel(s,parentLevels,result)
        
        %% structviewer
        varargout = structviewer(varargin)
        
    end %methods(Static)
end