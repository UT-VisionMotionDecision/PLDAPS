classdef params < handle
    properties
        structs
        structNames
        activeLevels
        topLevel
%         flatStructs %not a good name
                      
        flatStruct
%         flatStructLevels
%         flatStructIdMap
        
%         writeLockLevelList
        locked
        
        MethodsList
        
        Snew1
%         Snew2
    end
    
    methods 

        %% start new functions for new approach
        function p=params(s,sN,active)
                if nargin<2
                    sN=cellfun(@(x) sprintf('level%i',x),num2cell(1:length(s)),'UniformOutput',false);
                end
                if nargin<3
                    active=true(1,length(s));
                end
                p=addStructs(p,s,sN,active);
% %             attributes=?params;
% %             propertyList=attributes
% %          
            p.MethodsList={'view', 'setLevels','getAllLevels', 'mergeToSingleStruct','getDifferenceFromStruct','addLevels','addStructs','addNewStruct', 'getAllStructs','setLock','getParameter','fieldnames'};
%             p.structs=s;
%             p.activeLevels=1:length(s);
% %             p.flatStructLevels=p.levels;
%             if nargin>1
%                 p.structNames=sN;
%             else
%                 p.structNames=cellfun(@(x) sprintf('level%i',x),num2cell(1:length(s)),'UniformOutput',false);
%             end
%             
%             p = flattenStructs(p);
            
% %             p.readLock=false;
% %             p.writeLockLevelList=false(1,length(s));
% %             
% %             %helper things
                p.Snew1= substruct('.','structs','{}', {NaN});
% %             p.Snew2= substruct('.','flatStruct','()', {NaN}, '.', 'value');
        end %params(s,sN)
        
        % Overload fieldnames retrieval
        function names = fieldnames(p) 
            names={p.flatStruct(cellfun(@length,{p.flatStruct.parentLevels})==1).identifier};
            names=cellfun(@(x) x(2:end),names,'UniformOutput',false);
        end
        
        function disp(p)
            builtin('disp',p);
            
            fprintf('    with public methods:\n')
            fprintf('\t%s\n',p.MethodsList{:});
            
            fprintf('\n');
            names=fieldnames(p);
            fprintf('    with fieldnames:\n');
            fprintf('\t%s\n',names{:});
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
                active=~~active;
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
            levelNr=length(p.structs)+1;
            fs=p.getNextStructLevel(newStruct,{},[]);
            id=cellfun(@(x) sprintf('.%s',x{:}), {fs.parentLevels}, 'UniformOutput', false);   
            [fs.identifier]=deal(id{:});
            [fs.hierarchyLevels]=deal(levelNr);
            
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
                        p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = levelNr; 
                    else
                        p.flatStruct(end+1)=fs(iField);
                    end
                 end
            end
            
            p.structs{end+1}=newStruct;
            p.structNames{end+1}=newStructName;
            p.activeLevels(end+1)=makeActive;
            p.activeLevels=~~p.activeLevels;
            p.topLevel=find(p.activeLevels, 1, 'last');
        end
        
        function is = isField(p,fieldname)
            if(fieldname(1)~='.')
                fieldname=['.' fieldname];
            end
            
            is = ismember(fieldname,{p.flatStruct.identifier});
        end
        
        %TODO: if we allow dirty structs, we need to cosolidate....
        function p = setLevels(p,value)
            if islogical(value)
                if length(value)==length(p.struct) 
                    p.activeLevels=value;
                end
            elseif length(value)<length(p.structs)+1 && max(value)<=length(p.structs)
                p.activeLevels(:)=false;
                p.activeLevels(value)=true;
            end          
            p.topLevel=find(p.activeLevels, 1, 'last');
        end
        
        function l = getAllLevels(p)
            l=1:length(p.structs);
        end
        
        function [s, sN, active] = getAllStructs(p)
%         	p = consolidateToStructs(p);
            s=p.structs;
            sN=p.structNames;
            active=p.activeLevels;
        end
        
        function p = addField(p,id,value,levelNr) 
            %most ineficient way ever: but we are not planning on running
            %this during a trial (for now)
            if nargin<4
                levelNr=p.topLevel;
            end
            
            parentLevels=textscan(id,'%s','delimiter','.');
            parentLevels=parentLevels{1}(2:end);
            %assign the value, could probably use subsref of struct
            %instead.
%             evalc(['p.structs{levelNr)}' id '=value;']);
            Spartial=p.Snew1(ones(1,length(parentLevels)));
            [Spartial.subs]=deal(parentLevels{:});
            S=[p.Snew1 Spartial];
            S(2).subs={levelNr};
            [~]=builtin('subsasgn',p,S,value);
            
            if isstruct(value) %need to flatten that.
                addFlatStruct=p.getNextStructLevel(tmp,parentLevels,[]);
                id=cellfun(@(x) sprintf('.%s',x{:}), {addFlatStruct.parentLevels}, 'UniformOutput', false);   
                [addFlatStruct.identifier]=deal(id{:});
                [addFlatStruct.hierarchyLevels]=levelNr;
            
                [overruled, overruledPos]=ismember({addFlatStruct.identifier},{p.flatStruct.identifier});
                
                nFields=length(addFlatStruct);
                for iField=1:nFields
                    if overruled(iField)
                        if ~any(p.flatStruct(overruledPos(iField)).hierarchyLevels==levelNr) 
                            p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = levelNr; 
                        end
                    else
                        p.flatStruct(end+1)=addFlatStruct(iField);
                    end
                end
                
            else %simpler...but maybe not worth it
                [overruled, overruledPos]=ismember(id,{p.flatStruct.identifier});
                if overruled 
                    if ~any(p.flatStruct(overruledPos).hierarchyLevels==levelNr) 
                        p.flatStruct(overruledPos).hierarchyLevels(end+1)=levelNr;
                    end
                else
                    addFlatStruct.parentLevels=textscan(id,'%s','delimiter','.');
                    addFlatStruct.parentLevels=addFlatStruct.parentLevels{1}(2:end);
                    
                    addFlatStruct.isNode=false;
                    addFlatStruct.identifier=id;
                    addFlatStruct.hierarchyLevels=levelNr;
                    p.flatStruct(end+1) = addFlatStruct;
                end                
            end
        end
        
        function varargout =getParameter(p,id,levelNr)
            parentLevels=textscan(id,'%s','delimiter','.');
            parentLevels=parentLevels{1}(2:end);

            Spartial=p.Snew1(ones(1,length(parentLevels)));
            [Spartial.subs]=deal(parentLevels{:});

            if nargin<3 %from the merged dataset
                [varargout{1:nargout}] = subsref(p,Spartial);
            else
                S=[p.Snew1 Spartial];
                S(2).subs={levelNr};
                [varargout{1:nargout}] = builtin('subsref',p, S);
            end
        end
        
        %% end new functions for new approach
        
        function view(p)
           p.structviewer(p);
        end
%         
        function setLock(p,lock)
           p.locked = lock;
        end
%         
%         function setWriteLocks(p,locks)
%            if islogical(locks)
%                if length(locks)==1 || length(locks)==length(p.levels)
%                    p.writeLockLevelList(:)=locks;
%                else
%                    warning('params:setWriteLocks','Dimensions don''t match up');
%                end
%            else
%                p.writeLockLevelList(locks)=~p.writeLockLevelList(locks);
%            end
%         end
        
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
%                         if(p.readLock) %reading not allowed
%                             warning('parmas:subsref','Tried to acces data from @params class while readLock is set. Call setreadLock(false) to disable the lock.');
%                             varargout{1} = S;
%                             return
%                         end
%                         display(S);
                       
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
%                             tmp=struct;
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
                                
                        end

                   end
                otherwise
                    error('params:subsref', 'just don''t, ok? I''m a params class, so don''t go all brackety on me. Understood? I''m not an array, nor a cell. Is that explicit enough?');
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
                                
                                [~]=builtin('subsasgn',p,Snew,builtin('subsref',p,Sold));
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
            
%         function p = setLevels(p,value)
%             %are the new levels different?
%             if ~all(ismember(p.flatStructLevels,value)) || ~all(ismember(value,p.flatStructLevels))
%                 %make sure all changes are in the structs
%                 p = consolidateToStructs(p);
%                 %
%                 p.flatStructLevels=sort(value);
%                 %start again from scratch
%                 p = flattenStructs(p);
%             end
% %             
% %             if ~all(ismember(p.flatStructLevels,value)) || ~all(ismember(value,p.flatStructLevels))
% %                 p.flatStructLevels=sort(value); %ah, the flatStructs can be invalidated, as changes only occur to the flatStruct.
% %                 p = mergeFlatStructs(p); % =mergin them all, can reduce later
% %             end
%             
%         end
        

        
        
%         
%         function p=flattenStructs(p)
%             nStructs=length(p.structs);
%             for iStruct=1:nStructs
%                 flatStructs{iStruct}=p.getNextStructLevel(p.structs{iStruct},{},[]);
% %                 p.flatStructs{iStruct}(1)=[];
%                 flatStructs{iStruct}(1).parentLevels={''};
%                 flatStructs{iStruct}(1).value=struct;
%                 id=cellfun(@(x) sprintf('.%s',x{:}), {flatStructs{iStruct}.parentLevels}, 'UniformOutput', false);   
% %                 id=cellfun(@(x) x(1:end-1), id,'UniformOutput', false);
%                 [flatStructs{iStruct}.identifier]=deal(id{:});
%             end
% 
%             %assign some values about the hierarchy
%             for iStruct=1:nStructs
%                 [flatStructs{iStruct}.hierarchyTopLevel]=deal(iStruct);
%                 [flatStructs{iStruct}.hierarchyLevels]=deal(iStruct);
%                 %this is silly, how to to this in one line?
%                 nFields=length(p.flatStructs{iStruct});
%                 for(iField=1:nFields)
%                    flatStructs{iStruct}(iField).hierarchyValues={p.flatStructs{iStruct}(iField).value};
%                 end
%             end
%             
%             p = mergeFlatStructs(p); % =mergin them all, can reduce later
%         end %flattenStructs(p)
%         
%         function p = mergeFlatStructs(p)
%             %p.flatStructLevels=sort(levels); %for now I will now allow changing the hierarchy
%             
%             p.flatStruct=p.flatStructs{p.flatStructLevels(1)};
%             %next, merge them into one
%             for iStruct=p.flatStructLevels(2:end)
%                 %1: find the ones that are overruled (and newly defined (overruled==0
%                 %&overrluledPos==0
%                 [overruled, overruledPos]=ismember({p.flatStructs{iStruct}.identifier},{p.flatStruct.identifier});
% 
%                 [p.flatStruct(overruledPos(overruled)).hierarchyTopLevel]  =deal(iStruct);
%                 [p.flatStruct(overruledPos(overruled)).value]  = deal(p.flatStructs{iStruct}(overruled).value);
% 
%                 nFields=length(p.flatStructs{iStruct});
%                 for(iField=1:nFields)
%                     if(overruled(iField))
%                         p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = iStruct;
%                         p.flatStruct(overruledPos(iField)).hierarchyValues{end+1} = p.flatStructs{iStruct}(iField).value;
%                     else
%                         p.flatStruct(end+1)=p.flatStructs{iStruct}(iField);
%                     end            
%                 end
%             end 
%             
%             p.flatStructIdMap=containers.Map({p.flatStruct.identifier},1:length(p.flatStruct));
%         end %mergeFlatStructs(p, levels)
%         
%         %ok now generate the output
%         %merged struct: the struct as it's shown in the hierarical vie
%         %structs: the structs that lead to the merged struct
%         function p=consolidateToStructs(p)  
%             nFields=length(p.flatStruct);
% 
%             for iStruct=p.flatStructLevels
%                  p.structs{iStruct}=struct;
%             end
%             
%             
%             for iField=1:nFields
%                 if isstruct(p.flatStruct(iField).value) && length(p.flatStruct(iField).value)<2 %branch
%                     continue;
%                 end
%                 for level_index=1:length(p.flatStruct(iField).hierarchyLevels)
%                     iStruct=p.flatStruct(iField).hierarchyLevels(level_index); %#ok<NASGU>
%                     %does a value exist at this level?
%                     evalc(['p.structs{iStruct}' p.flatStruct(iField).identifier '=p.flatStruct(iField).hierarchyValues{level_index};']);
%                 end
%             end
%             
% %             %the code above is at least a little faster.
% %             for iStruct=p.flatStructLevels %only touch the ones that were
% %                 tmp=struct;
% % 
% %                 for iField=1:nFields
% %                     %does a value exist at this level?
% %                     level_index=(p.flatStruct(iField).hierarchyLevels==iStruct);
% %                     if any(level_index) && ~isstruct(p.flatStruct(iField).hierarchyValues{level_index}) 
% %                         evalc(['tmp' p.flatStruct(iField).identifier '=p.flatStruct(iField).hierarchyValues{level_index};']);
% %                     end
% %                 end
% % 
% %                 p.structs{iStruct}=tmp;
% %             end
%         end %consolidateToStructs
%         
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
                
%                 
%                 %%could all be subrefed instead. check how much speed
%                 %%improvement that would bring
%                 evalc(['tmp=p.structs{level_index}' p.flatStruct(iField).identifier ';']);
%                 
%                 if ~isstruct(tmp) 
%                     evalc(['mergedStruct' p.flatStruct(iField).identifier '=tmp;']);
%                 end

%                   evalc(['mergedStruct' p.flatStruct(iField).identifier '=p.structs{level_index}' p.flatStruct(iField).identifier ';']);
            end
            
        end %mergedStruct=mergeToSingleStruct(p)  

        %return the differerence of a struct to this classes active version
        function dStruct = getDifferenceFromStruct(p,newStruct)
            newFlatStruct=p.getNextStructLevel(newStruct,{},[]);
%             newFlatStruct(1)=[];
            newFlatStruct(1).parentLevels={''};
            id=cellfun(@(x) sprintf('.%s',x{:}), {newFlatStruct.parentLevels}, 'UniformOutput', false);   
            [newFlatStruct.identifier]=deal(id{:});
            
            %we will not handle the possibility newStruct is missing a fieled
            removedFields=~ismember({p.flatStruct.identifier},id);
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
%                     evalc(['newValue=newStruct' newFlatStruct(iField).identifier ';']);
%                     evalc(['oldValue=p.structs{level_index}' p.flatStruct(fS_index).identifier ';']);
                
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
%                     evalc(['dStruct' newFlatStruct(iField).identifier '=newStruct' newFlatStruct(iField).identifier ';']);
                 end
            end
            
        end %dStruct = getDifferenceFromStruct(p,newStruct)
        
        
    end %methods
    
    methods(Static)
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
                elseif ~isempty(value)
                    vs = [ '[ ' vs ' ]' ];
                end
                vs=strtrim(vs);
            end
        end %valueString(value)
        
        function result=getNextStructLevel(s,parentLevels,result)
            if isstruct(s) && length(s)<2
                r.parentLevels=parentLevels;
                r.isNode=true;
%                 r.value=struct;
                result(end+1)=r;

                fn=fieldnames(s);
                nFields=length(fn);
                for iField=1:nFields
                    lev=parentLevels;
                    lev(end+1)=fn(iField); %#ok<AGROW>
                    result=params.getNextStructLevel(s.(fn{iField}),lev,result);
        %             result=[result r];
                end
            else %leaf
                r.parentLevels=parentLevels;
                r.isNode=false;
%                 r.value=s;
                result(end+1)=r;
            end
        end %result=getNextStructLevel(s,parentLevels,result)
        
        varargout = structviewer(varargin)
        
    end %methods(Static)
end