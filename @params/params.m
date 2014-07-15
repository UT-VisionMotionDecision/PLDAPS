classdef params < handle
    properties
        structs
        structNames
        levels
        flatStructs %not a good name
                      
        flatStruct
        flatStructLevels
        flatStructIdMap
        
        MethodsList
        
        Snew1
        Snew2
    end
    
    methods 
        function p=params(s,sN)
%             attributes=?params;
%             propertyList=attributes
%          
            p.MethodsList={'view', 'setLevels','getAllLevels', 'mergeToSingleStruct','getDifferenceFromStruct','addLevels' 'getAllStructs'};
            p.structs=s;
            p.levels=1:length(s);
            p.flatStructLevels=p.levels;
            if nargin>1
                p.structNames=sN;
            else
                p.structNames=num2cell(p.levels);
            end
            
            p = flattenStructs(p);
            
            %helper things
            p.Snew1= substruct('.','flatStruct','()', {NaN}, '.', 'hierarchyValues', '{}',{NaN});
            p.Snew2= substruct('.','flatStruct','()', {NaN}, '.', 'value');
        end %params(s,sN)
        
        function view(p)
           p.structviewer(p);
        end
        
        function varargout = subsref(p,S)
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
                        % get a value from the flatStruct
                        %how many .?
                        dotNr=find(diff(strcmp({S.type}, '.'))==-1);
                        if isempty(dotNr) % no -1, means only '.' in there
                            dotNr=length(S);
                        end
                        k={S(1:dotNr).type; S(1:dotNr).subs};
                        id=[k{:}];
%                         id=sprintf('.%s',S(1:dotNr).subs); %slower
                        
                        id_index=p.flatStructIdMap(id);
                        p.Snew2(2).subs={id_index};
                         
                        [varargout{1:nargout}] = builtin('subsref',p, [p.Snew2 S(dotNr+1:end)]);
                        
                        %trying to access
                        if(dotNr==length(S) && isstruct(varargout{1}))
                            parts_inds=find(strncmp({p.flatStruct.identifier},id,length(id)));
%                             parts_inds=strfind({p.flatStruct.identifier},id);
%                             parts_inds=find(cellfun(@(x) ~isempty(x)&&x==1,parts_inds));
                            
                            for iPart=parts_inds
                               evalc(['tmp' p.flatStruct(iPart).identifier '=p.flatStruct(iPart).value']) ;
                            end
                            
                            evalc(['varargout{1}=tmp' id]);
                                
                                
                        end
                   end
                otherwise
                    error('params:subsref', 'just don''t, ok? I''m a params clas, so don''t go all brackety on me. Understood? I''m not an array, nor a cell. Is that explicit enough?');
            end
        end
        
        %because all external calls end up here, this makes all properties
        %protextec from changes.
        function p = subsasgn(p,S,value)
            %copying a class, but its a handle class,i.e. we expect it to
            %be just the handle
            if isempty(S) && isa(p,'params')
                %% 
                return;
            end
            
            switch S(1).type
             % Use the built-in subsasagn for dot notation
                case '.'
                    % get a value from the flatStruct
                    %how many .?
                    dotNr=find(diff(strcmp({S.type}, '.'))==-1);
                    if isempty(dotNr) % no -1, meanst only '.' in there
                        dotNr=length(S);
                    end
                    id=sprintf('.%s',S(1:dotNr).subs);
%                     id(end)=[];
                    
                    id_iskey=p.flatStructIdMap.isKey(id);
                    if id_iskey
                        id_index=p.flatStructIdMap(id);
                        p.Snew1(2).subs={id_index};
                        
                        addToLevel=max(p.flatStructLevels);
                        addPosition=find(p.flatStruct(id_index).hierarchyLevels==addToLevel,1);
                        if isempty(addPosition) %first time this value is assigned atp.flatStruct(id_index) this level
                            p.Snew1(4).subs={1};
                            p.flatStruct(id_index).hierarchyLevels(end+1) = addToLevel;
                            p.flatStruct(id_index).hierarchyTopLevel = addToLevel;
                            addPosition=find(p.flatStruct(id_index).hierarchyLevels==addToLevel,1);
                        end
                        p.Snew1(4).subs={addPosition};
                        p.Snew2(2).subs={id_index};

                        S1=[p.Snew1 S(dotNr+1:end)];
                        S2=[p.Snew2 S(dotNr+1:end)];

                        [~]=builtin('subsasgn',p,S1,value);
                        [~]=builtin('subsasgn',p,S2,value);
                    else
                        p.addField(id,value);
                    end
                otherwise
                    error('params:subsassign', 'just don''t, ok? I''m a params clas, so don''t go all brackety on me. Understood? I''m not an array, nor a cell. Is that explicit enough?');
            end
                    
        end
            
        function is = isField(p,fieldname)
            if(fieldname(1)~='.')
                fieldname=['.' fieldname];
            end
            is = p.flatStructIdMap.isKey(fieldname);
        end
        
        function p = setLevels(p,value)
            %are the new levels different?
            if ~all(ismember(p.flatStructLevels,value)) || ~all(ismember(value,p.flatStructLevels))
                %make sure all changes are in the structs
                p = consolidateToStructs(p);
                %
                p.flatStructLevels=sort(value);
                %start again from scratch
                p = flattenStructs(p);
            end
%             
%             if ~all(ismember(p.flatStructLevels,value)) || ~all(ismember(value,p.flatStructLevels))
%                 p.flatStructLevels=sort(value); %ah, the flatStructs can be invalidated, as changes only occur to the flatStruct.
%                 p = mergeFlatStructs(p); % =mergin them all, can reduce later
%             end
            
        end
        
        function l = getAllLevels(p)
            l=p.levels;
        end
        
        function [s, sN] = getAllStructs(p)
        	p = consolidateToStructs(p);
            s=p.structs;
            sN=p.structNames;
        end
        
        function p = addField(p,id,value) %#ok<INUSD>
            %most ineficient way ever: but we are not planning on running
            %this during a trial (for now)
            evalc(['tmp' id '=value;']);
            addFlatStruct=p.getNextStructLevel(tmp,{},[]);
            id=cellfun(@(x) sprintf('.%s',x{:}), {addFlatStruct.parentLevels}, 'UniformOutput', false);   
            [addFlatStruct.identifier]=deal(id{:});
            [addFlatStruct.hierarchyTopLevel]=deal(max(p.levels));
            [addFlatStruct.hierarchyLevels]=deal(max(p.levels));
%             [addFlatStruct(:).hierarchyValues]=addFlatStruct(:).value;
            nFields=length(addFlatStruct);
            for(iField=1:nFields)
                [addFlatStruct(iField).hierarchyValues]={addFlatStruct(iField).value};
            end
            
            newKeys=~p.flatStructIdMap.isKey(id);
            nNewKeys=sum(newKeys);
            fieldNrs=length(p.flatStruct)+ (1:nNewKeys);
            p.flatStruct(fieldNrs)=addFlatStruct(newKeys);
            
            newMap=containers.Map(id(newKeys),fieldNrs);
            p.flatStructIdMap=vertcat(p.flatStructIdMap, newMap);
            
        end
        
        function p=addLevels(p,s,sN,setLevels)
            if nargin<4
                setLevels=true;
            end
            
        	%make sure all changes are in the structs
            p = consolidateToStructs(p);
            
            nOld=length(p.structNames);
            nAdd=length(sN);
            [p.structs{nOld+1:nOld+nAdd}]=s{:};
            [p.structNames{nOld+1:nOld+nAdd}]=sN{:};
            p.levels=1:(nOld+nAdd);
            
            if(setLevels)
                if islogical(setLevels)
                    p.flatStructLevels= [p.flatStructLevels nOld+1:nOld+nAdd];
                else
                    p.flatStructLevels= setLevels;
                end
            end
            
            p = flattenStructs(p);
            
        end %p=addLevels(p,s,sN)
        
        function p=flattenStructs(p)
            nStructs=length(p.structs);
            for iStruct=1:nStructs
                p.flatStructs{iStruct}=p.getNextStructLevel(p.structs{iStruct},{},[]);
%                 p.flatStructs{iStruct}(1)=[];
                p.flatStructs{iStruct}(1).parentLevels={''};
                p.flatStructs{iStruct}(1).value=struct;
                id=cellfun(@(x) sprintf('.%s',x{:}), {p.flatStructs{iStruct}.parentLevels}, 'UniformOutput', false);   
%                 id=cellfun(@(x) x(1:end-1), id,'UniformOutput', false);
                [p.flatStructs{iStruct}.identifier]=deal(id{:});
            end

            %assign some values about the hierarchy
            for iStruct=1:nStructs
                [p.flatStructs{iStruct}.hierarchyTopLevel]=deal(iStruct);
                [p.flatStructs{iStruct}.hierarchyLevels]=deal(iStruct);
                %this is silly, how to to this in one line?
                nFields=length(p.flatStructs{iStruct});
                for(iField=1:nFields)
                   p.flatStructs{iStruct}(iField).hierarchyValues={p.flatStructs{iStruct}(iField).value};
                end
            end
            
            p = mergeFlatStructs(p); % =mergin them all, can reduce later
        end %flattenStructs(p)
        
        function p = mergeFlatStructs(p)
            %p.flatStructLevels=sort(levels); %for now I will now allow changing the hierarchy
            
            p.flatStruct=p.flatStructs{p.flatStructLevels(1)};
            %next, merge them into one
            for iStruct=p.flatStructLevels(2:end)
                %1: find the ones that are overruled (and newly defined (overruled==0
                %&overrluledPos==0
                [overruled, overruledPos]=ismember({p.flatStructs{iStruct}.identifier},{p.flatStruct.identifier});

                [p.flatStruct(overruledPos(overruled)).hierarchyTopLevel]  =deal(iStruct);
                [p.flatStruct(overruledPos(overruled)).value]  = deal(p.flatStructs{iStruct}(overruled).value);

                nFields=length(p.flatStructs{iStruct});
                for(iField=1:nFields)
                    if(overruled(iField))
                        p.flatStruct(overruledPos(iField)).hierarchyLevels(end+1) = iStruct;
                        p.flatStruct(overruledPos(iField)).hierarchyValues{end+1} = p.flatStructs{iStruct}(iField).value;
                    else
                        p.flatStruct(end+1)=p.flatStructs{iStruct}(iField);
                    end            
                end
            end 
            
            p.flatStructIdMap=containers.Map({p.flatStruct.identifier},1:length(p.flatStruct));
        end %mergeFlatStructs(p, levels)
        
        %ok now generate the output
        %merged struct: the struct as it's shown in the hierarical vie
        %structs: the structs that lead to the merged struct
        function p=consolidateToStructs(p)  
            nFields=length(p.flatStruct);

            for iStruct=p.flatStructLevels
                 p.structs{iStruct}=struct;
            end
            
            
            for iField=1:nFields
                if isstruct(p.flatStruct(iField).value) && length(p.flatStruct(iField).value)<2 %branch
                    continue;
                end
                for level_index=1:length(p.flatStruct(iField).hierarchyLevels)
                    iStruct=p.flatStruct(iField).hierarchyLevels(level_index); %#ok<NASGU>
                    %does a value exist at this level?
                    evalc(['p.structs{iStruct}' p.flatStruct(iField).identifier '=p.flatStruct(iField).hierarchyValues{level_index};']);
                end
            end
            
%             %the code above is at least a little faster.
%             for iStruct=p.flatStructLevels %only touch the ones that were
%                 tmp=struct;
% 
%                 for iField=1:nFields
%                     %does a value exist at this level?
%                     level_index=(p.flatStruct(iField).hierarchyLevels==iStruct);
%                     if any(level_index) && ~isstruct(p.flatStruct(iField).hierarchyValues{level_index}) 
%                         evalc(['tmp' p.flatStruct(iField).identifier '=p.flatStruct(iField).hierarchyValues{level_index};']);
%                     end
%                 end
% 
%                 p.structs{iStruct}=tmp;
%             end
        end %consolidateToStructs
        
        %ok now generate the output
        %merged struct: the struct as it's shown in the hierarical vie
        %structs: the structs that lead to the merged struct
        function mergedStruct=mergeToSingleStruct(p)  
            %remove branches
%             p.flatStruct(cellfun(@isstruct,{p.flatStruct.value}))=[];

            mergedStruct=struct;
            nFields=length(p.flatStruct);
            for iField=1:nFields
                level_index=p.flatStruct(iField).hierarchyLevels==p.flatStruct(iField).hierarchyTopLevel; 
                if ~isstruct(p.flatStruct(iField).hierarchyValues{level_index}) 
                    evalc(['mergedStruct' p.flatStruct(iField).identifier '=p.flatStruct(iField).hierarchyValues{level_index};']);
                end
            end
            
        end %mergedStruct=mergeToSingleStruct(p)  

        %return the differerence of a struct to the classes version
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
            
            newFields=~ismember(id,{p.flatStruct.identifier});
            
            nFields=length(newFlatStruct);
            for iField=1:nFields
                if newFields(iField)
                    continue;
                end
                
                fS_index=p.flatStructIdMap(newFlatStruct(iField).identifier);
                
                newFields(iField) = ~(strcmp(class(p.flatStruct(fS_index).value),class(newFlatStruct(iField).value)) && isequal(p.flatStruct(fS_index).value,newFlatStruct(iField).value));
            end
            
            dStruct=struct;          
            for iField=1:nFields
                if newFields(iField)
                    evalc(['dStruct' newFlatStruct(iField).identifier '=newFlatStruct(iField).value;']);
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
                r.value=struct;
                result(end+1)=r;

                fn=fieldnames(s);
                nFields=length(fn);
                for(iField=1:nFields)
                    lev=parentLevels;
                    lev(end+1)=fn(iField); %#ok<AGROW>
                    result=params.getNextStructLevel(s.(fn{iField}),lev,result);
        %             result=[result r];
                end
            else %leaf
                r.parentLevels=parentLevels;
                r.value=s;
                result(end+1)=r;
            end
        end %result=getNextStructLevel(s,parentLevels,result)
        
        varargout = structviewer(varargin)
        
    end %methods(Static)
end