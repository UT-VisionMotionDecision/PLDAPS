function varargout = structviewer(varargin)
% structviewer Application M-file for structviewer.fig
%   structviewer, by itself, creates a new structviewer or raises the existing
%   singleton*.
%
%   H = structviewer returns the handle to a new structviewer or the handle to
%   the existing singleton*.
%
%   structviewer('CALLBACK',hObject,eventData,handles,...) calls the local
%   function named CALLBACK in structviewer.M with the given input arguments.
%
%   structviewer('Property','Value',...) creates a new structviewer or raises the
%   existing singleton*.  Starting from the left, property value pairs are
%   applied to the GUI before structviewer_OpeningFunction gets called.  An
%   unrecognized property name or invalid value makes property application
%   stop.  All inputs are passed to structviewer_OpeningFcn via varargin.
%
%   *See GUI Options - GUI allows only one instance to run (singleton).
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2000-2006 The MathWorks, Inc.

% Edit the above text to modify the response to help structviewer

% Last Modified by GUIDE v2.5 24-Apr-2014 13:10:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',          mfilename, ...
                   'gui_Singleton',     gui_Singleton, ...
                   'gui_OpeningFcn',    @structviewer_OpeningFcn, ...
                   'gui_OutputFcn',     @structviewer_OutputFcn, ...
                   'gui_LayoutFcn',     [], ...
                   'gui_Callback',      []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before structviewer is made visible.
function structviewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to structviewer (see VARARGIN)

% Choose default command line output for structviewer
    handles.output = hObject;
    handles.param = varargin{1};

    % copy structs from params
    % copy because we don't want to change the classes values only once we
    % click save
    [s, sN, active]=getAllStructs(handles.param);
    handles.backup={s, sN, active};
    
%     handles.flatStruct=handles.param.flatStruct;
%     handles.structInfo.levels=handles.param.flatStructLevels;
%     handles.structInfo.nLevels=length(handles.structInfo.levels);
%     handles.structInfo.levelNames=handles.param.structNames(handles.structInfo.levels);
    handles.robot_in_action=false;
    % setListboxes(handles,flatStruct)

    % Update handles structure
    guidata(hObject, handles);

    % Populate the listbox
    setListboxes(handles);


function setListboxes(handles,selectedID, selectedHierarchy)
    %they are merged. let's sort by identifier
    flatStruct=handles.param.flatStruct;
    
    flatStruct(cellfun(@isempty,{flatStruct.parentLevels}))=[];
    
    levelNames=handles.param.structNames;
%     nLevels=length(levelNames);
    activeLevels=find(handles.param.activeLevels);
    nActiveLevels=length(activeLevels);

    [~, sortIdsIdx]=sort({flatStruct.identifier});
    flatStruct=flatStruct(sortIdsIdx);

    if nargin<2
        field_index=1;
        selectedID=flatStruct(1).identifier;
    else
        field_index=find(strcmp({flatStruct.identifier},selectedID));
    end

    colors=distinguishable_colors(nActiveLevels,{'w','k'});
    colorsTree=colors/2;
    structInfo.colors=colors;
    structInfo.colorsTree=colorsTree;
    structInfo.currentValues=cell(1,nActiveLevels);
    structInfo.currentValueStrings=cell(1,nActiveLevels);
    
    colorString=cell(1,nActiveLevels);
    colorTreeString=cell(1,nActiveLevels);
    for iLevel=1:nActiveLevels
        colorString{iLevel}=sprintf('%s',dec2hex(round(structInfo.colors(iLevel,:)*255))');
        colorTreeString{iLevel}='000000';%sprintf('%s',dec2hex(round(handles.structInfo.colorsTree(iLevel,:)*255))');
    end
%     structInfo.colorString=colorString;
%     structInfo.colorTreeString=colorTreeString;

    
    flatStruct(cellfun(@(x) ~any(ismember(x,activeLevels)),{flatStruct.hierarchyLevels}))=[];
    
    nFields=length(flatStruct);
    for iField=1:nFields
        hierarchy_index=activeLevels==max(flatStruct(iField).hierarchyLevels);
        if flatStruct(iField).isNode
            flatStruct(iField).string=sprintf(['<HTML><pre><FONT color=%s>' repmat(' ',[1 length(flatStruct(iField).parentLevels)-1]) '- ' '.%s</FONT></HTML>'],colorTreeString{hierarchy_index},flatStruct(iField).parentLevels{end});
        else
            flatStruct(iField).string=sprintf(['<HTML><pre><FONT color=%s>' repmat(' ',[1 length(flatStruct(iField).parentLevels)]) '  .%s</FONT></HTML>'],colorString{hierarchy_index},flatStruct(iField).parentLevels{end});
        end
    end

    for iField=1:nFields
        if(flatStruct(iField).isNode)%branch
            flatStruct(iField).valueString='';
        else
            flatStruct(iField).valueString=params.valueString(getParameter(handles.param,flatStruct(iField).identifier));%evalc('disp(flatStruct(iField).value)');
        end
    end
    
    levelNamesColored=cell(1,nActiveLevels);
    for iLevel=1:nActiveLevels
        levelNamesColored{iLevel}=sprintf('<HTML><pre><FONT color=%s>%s</FONT></HTML>',colorString{iLevel},levelNames{activeLevels(iLevel)});
    end
    handles.structInfo.levelDisplayNames=levelNames(activeLevels);
    handles.structInfo.levelDisplayColors=colorString;

%     handles.flatStruct=flatStruct;
    set(handles.listbox1,'String',{flatStruct.string}',...
        'Value',1)
    set(handles.listbox2,'String',{flatStruct.valueString}',...
        'Value',1)
    set(handles.structListbox,'String',levelNamesColored,...
        'Value',1)
    set(handles.structValueListbox,'String',structInfo.currentValueStrings,...
        'Value',1)
    set(handles.structListbox,'Max',nActiveLevels);
%     set(handles.structValueListbox,'Max',nLevels);




    handles.idList={flatStruct.identifier};
    handles.levelList=levelNames(activeLevels);
    
    guidata(handles.figure1,handles)

    set(handles.listbox1,'Value', field_index);
    set(handles.listbox2,'Value', field_index);

    if nargin<3
        setStructListbox(handles,selectedID);%?
    else
        setStructListbox(handles,selectedID,selectedHierarchy);
    end



% --- Outputs from this function are returned to the command line.
function varargout = structviewer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% this gets called just after it's visible, so its the best place to to the
% findobj calls, as it makes invisible object visible while searching....
%     jScrollPane = findjobj(handles.listbox2); 
%     jListbox = jScrollPane.getViewport.getComponent(0);
%     set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);
% 
%     jScrollPane = findjobj(handles.listbox1); 
%     jListbox = jScrollPane.getViewport.getComponent(0);
%     set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);
% 
%     jScrollPane = findjobj(handles.structListbox); 
%     jListbox = jScrollPane.getViewport.getComponent(0);
%     set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);
% 
%     jScrollPane = findjobj(handles.structValueListbox); 
%     jListbox = jScrollPane.getViewport.getComponent(0);
%     set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);
%    
    [jScrollBar]=findjobj(handles.listbox1,'class','com.mathworks.hg.peer.utils.UIScrollPane');
    set(handle(jScrollBar,'CallbackProperties'),'AdjustmentValueChangedCallback',{@listbox1_ScrollCallback, handles.listbox1 });
    set(jScrollBar,'VerticalScrollBarPolicy',22); 
    
    [jScrollBar]=findjobj(handles.listbox2,'class','com.mathworks.hg.peer.utils.UIScrollPane');
    set(handle(jScrollBar,'CallbackProperties'),'AdjustmentValueChangedCallback',{@listbox2_ScrollCallback, handles.listbox1 });
    set(jScrollBar,'VerticalScrollBarPolicy',22); 
    
    varargout{1} = handles.output;
    
function listbox1_ScrollCallback(hObject, eventdata, listbox1_handle)    
handles=guidata(listbox1_handle);

l1_position=get(handles.listbox1,'ListboxTop');
l2_position=get(handles.listbox2,'ListboxTop');

if(l1_position~=l2_position)
    set(handles.listbox2,'ListboxTop',l1_position)
end


function listbox2_ScrollCallback(hObject, eventdata, listbox2_handle)    
handles=guidata(listbox2_handle);

l1_position=get(handles.listbox1,'ListboxTop');
l2_position=get(handles.listbox2,'ListboxTop');

if(l1_position~=l2_position)
    set(handles.listbox1,'ListboxTop',l2_position)
end

    
% ------------------------------------------------------------
% Callback for list box - open .fig with guide, otherwise use open
% ------------------------------------------------------------
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

    index_selected = get(handles.listbox1,'Value');
    set(handles.listbox2,'Value', index_selected);
    setStructListbox(handles,handles.idList{index_selected});    


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
% usewhitebg = 1;
% if usewhitebg
    set(hObject,'BackgroundColor','white');
% else
%     set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
% end

% jScrollPane = findjobj(hObject); 
% jListbox = jScrollPane.getViewport.getComponent(0);
% set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);%Color(0.2,0.2,0.2)

% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Add the current directory to the path, as the pwd might change thru' the
% gui. Remove the directory from the path when gui is closed 
% (See figure1_DeleteFcn)
% setappdata(hObject, 'StartPath', pwd);
% addpath(pwd);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Remove the directory added to the path in the figure1_CreateFcn.
% if isappdata(hObject, 'StartPath')
%     rmpath(getappdata(hObject, 'StartPath'));
% end



% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
    index_selected = get(handles.listbox2,'Value');
    set(handles.listbox1,'Value', index_selected);
    setStructListbox(handles,handles.idList{index_selected});


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% jScrollPane = findjobj(hObject); 
% jListbox = jScrollPane.getViewport.getComponent(0);
% set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);%Color(0.2,0.2,0.2)


% --- Executes on selection change in structListbox.
function structListbox_Callback(hObject, eventdata, handles)
% hObject    handle to structListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns structListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from structListbox
% index_selected = get(handles.structListbox,'Value');
% set(handles.structValueListbox,'Value', index_selected);


% --- Executes during object creation, after setting all properties.
function structListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to structListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'Enable','inactive');
% 
% jScrollPane = findjobj(hObject); 
% jListbox = jScrollPane.getViewport.getComponent(0);
% set(jListbox, 'SelectionBackground',[0.8 0.8 0.8]);%Color(0.2,0.2,0.2)


% --- Executes on selection change in structValueListbox.
function structValueListbox_Callback(hObject, eventdata, handles)
% hObject    handle to structValueListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns structValueListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from structValueListbox
    selectedId=     handles.idList{get(handles.listbox1,'Value')};
    level_selected = get(handles.structValueListbox,'Value');
    %setFieldEditor(handles,index_selected);
    setStructListbox(handles,selectedId,handles.levelList{level_selected});

    flatStruct=handles.param.flatStruct;
    activeLevels=find(handles.param.activeLevels);
    field_index=(strcmp(selectedId,{flatStruct.identifier}));
    
    field=flatStruct(field_index);
    
    if strcmp(get(handles.figure1,'SelectionType'),'open')
        %add right click mouse actions: move along hierarchy | delete entry
        hcmenu = uicontextmenu('Parent',handles.figure1);
        if ~field.isNode %it's not a tree branch
            nLevels=length(activeLevels);
            colorString=handles.structInfo.levelDisplayColors;

            for iLevel=1:nLevels
                if(iLevel==level_selected)
                    continue;
                end
                menuText=sprintf('<HTML>Assign from <FONT color=%s>%s</FONT> to <FONT color=%s>%s</FONT></HTML>',colorString{level_selected}, handles.structInfo.levelDisplayNames{level_selected}, colorString{iLevel}, handles.structInfo.levelDisplayNames{iLevel});
                cb={@structValueListbox_Reassign,activeLevels(level_selected), activeLevels(iLevel)};
                uimenu(hcmenu, 'Label', menuText, 'Callback', cb);
            end

            menuText=sprintf('<HTML>Delete from <FONT color=%s>%s</FONT></HTML>',colorString{level_selected}, handles.structInfo.levelDisplayNames{level_selected});
            cb={@structValueListbox_Reassign, activeLevels(level_selected)};
            uimenu(hcmenu, 'Label', menuText, 'Callback', cb,'Separator','on');
        end
    %     set(handles.structValueListbox,'uicontextmenu',hcmenu)
        set(handles.figure1,'uicontextmenu',hcmenu)
        fig1Units=get(handles.figure1,'units');
        set(handles.figure1,'units','pixels');
        fig1Pos=get(handles.figure1,'Position');
        currentMouse=get(0,'PointerLocation');%get(handles.figure1,'CurrentPoint');
        pos=currentMouse-fig1Pos(1:2);
        set(hcmenu,'Position',pos);
        set(handles.figure1,'units',fig1Units);
        set(hcmenu,'Visible','on');
    end
% set(handles.structListbox,'Value', index_selected);

% --- Executes during object creation, after setting all properties.
function structValueListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to structValueListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    % set(hObject,'Enable','inactive');
    set(hObject,'Enable','on');


function setStructListbox(handles,selectedId,selectedHierarchy)
    %get current field:
    flatStruct=handles.param.flatStruct;
    activeLevels=find(handles.param.activeLevels);
    
    
    field_index=(strcmp(selectedId,{flatStruct.identifier}));
    
    field=flatStruct(field_index);
    
    if(nargin<3)
        full_index=max(field.hierarchyLevels);
        selectedHierarchy=handles.param.structNames{full_index};
        index=find(activeLevels==full_index);
    else
        full_index=find(strcmp(selectedHierarchy,handles.param.structNames));
        index=find(activeLevels==full_index);
    end
    
    %select the names of the structs that define this field:
    set(handles.structListbox,'Value',find(ismember(activeLevels,field.hierarchyLevels)));
    %and display the values of these next to them
    nLevels=length(activeLevels);
    valueStrings=cell(1,nLevels);
    values=cell(1,nLevels);
    for iLevel=1:nLevels
        isFieldLevel=any(field.hierarchyLevels==activeLevels(iLevel));
        if isFieldLevel && ~field.isNode
            values{iLevel}=getParameter(handles.param,selectedId,activeLevels(iLevel));
            valueStrings{iLevel}=params.valueString(values{iLevel});%evalc('disp(values{iLevel})');
        end
    end
    
    set(handles.structValueListbox,'String',valueStrings);
%     handles.structInfo.currentValueStrings=valueStrings;
%     handles.structInfo.currentField=field_index;
%     handles.structInfo.currentHierarchy=index;
%     handles.structInfo.currentLevel=handles.structInfo.levels(index);
%     handles.structInfo.currentValues = values;
    
    %select the value that is currenty used in the merged struct
    set(handles.structValueListbox,'Value', index);
    
    % set(handles.fieldEditor,'String',values{field.hierarchyTopLevel});
    setFieldEditor(handles,selectedId,selectedHierarchy);
         
    guidata(handles.figure1,handles);
    
    
function setFieldEditor(handles,selectedId,selectedHierarchy)
    flatStruct=handles.param.flatStruct;
%     activeLevels=find(handles.param.activeLevels);
    field_index=(strcmp(selectedId,{flatStruct.identifier}));
    field=flatStruct(field_index);
    if(nargin<3)
        full_index=max(field.hierarchyLevels);
%         selectedHierarchy=handles.param.structNames{full_index};
%         index=find(activeLevels==full_index);
    else
        full_index=find(strcmp(selectedHierarchy,handles.param.structNames));
%         index=find(activeLevels==full_index);
    end
    
    if field.isNode
        set(handles.fieldEditor,'Enable','inactive');
    else
        
        if any(field.hierarchyLevels==full_index)
            valueString=params.valueString(getParameter(handles.param,selectedId,full_index));
        else
            valueString='';
        end

        set(handles.fieldEditor,'String',valueString);
   
        set(handles.fieldEditor,'Enable','on');
    end


function fieldEditor_Callback(hObject, eventdata, handles) %#ok<*INUSL>
% hObject    handle to fieldEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fieldEditor as text
%        str2double(get(hObject,'String')) returns contents of fieldEditor as a double

%pressed enter (I hope)
    if strcmp(get(handles.figure1,'SelectionType'),'normal');
        selectedId=     handles.idList{get(handles.listbox1,'Value')};
        level_selected = get(handles.structValueListbox,'Value');
        flatStruct=handles.param.flatStruct;
        activeLevels=find(handles.param.activeLevels);
        full_index=activeLevels(level_selected);
        
        field_index=(strcmp(selectedId,{flatStruct.identifier}));
        field=flatStruct(field_index);
        
        try
            if any(field.hierarchyLevels==full_index)
                value=getParameter(handles.param, selectedId, activeLevels(level_selected));
            end
            evalc(['value=' get(handles.fieldEditor,'String')]);
%             valueString=params.valueString(value);%a first kind of text that it might hve worked.

            addField(handles.param,selectedId,value,activeLevels(level_selected)); 
%             if any(field.hierarchyLevels==activeLevels(level_selected)) %parameter changed
%                 field.hierarchyValues{field.hierarchyLevels==handles.structInfo.currentLevel}=value;
%             else %parameter is new to that level
%                 field.hierarchyValues{end+1}=value;
%                 field.hierarchyLevels(end+1)=handles.structInfo.currentLevel;
%                 [~,idx]=sort(field.hierarchyLevels);
%                 field.hierarchyValues=field.hierarchyValues(idx);
%                 field.hierarchyLevels=field.hierarchyLevels(idx);
%             end
% 
%             if activeLevels(level_selected)==max(field.hierarchyLevels) %it's at the top of the hierarchy
%                 field.value=value;
%                 field.valueString=valueString;
%                 field.hierarchyTopLevel=handles.structInfo.currentLevel;
%             end
%             handles.flatStruct(handles.structInfo.currentField)=field;
%             guidata(handles.figure1,handles);

            if level_selected>=max(field.hierarchyLevels) %it's at the top of the hierarchy
                %reload everything
                setListboxes(handles,selectedId, handles.levelList{activeLevels(level_selected)});
            else
                setStructListbox(handles,selectedId,handles.levelList{activeLevels(level_selected)});
            end      


        catch ME
            display(ME);
        end

    end

% --- Executes during object creation, after setting all properties.
function fieldEditor_CreateFcn(hObject, eventdata, handles) %#ok<*DEFNU,*INUSD>
% hObject    handle to fieldEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject,'Max',1)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over structValueListbox.
function structValueListbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to structValueListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
function structValueListbox_Reassign(hObject,eventData,from,to)
    handles=guidata(hObject);
%     field=handles.flatStruct(handles.structInfo.currentField);
    
     selectedId=     handles.idList{get(handles.listbox1,'Value')};
     flatStruct=handles.param.flatStruct;
     field_index=(strcmp(selectedId,{flatStruct.identifier}));
     field=flatStruct(field_index);
    
    if nargin>2 %move or delete a value
%         from_index=field.hierarchyLevels==from;
        %was the hierarchyTopLevel involved?
        top_involved= from==max(field.hierarchyLevels);
        if nargin==3    
            to=from;
        end

        %move and delete
%         to_index=field.hierarchyLevels==to;
%         field.hierarchyLevels(from_index)=to;

        top_involved=top_involved | to>=max(field.hierarchyLevels);
       
        thisSubID=field.parentLevels;
        Spartial=handles.param.Snew1(ones(1,length(thisSubID)));
        [Spartial.subs]=deal(thisSubID{:});
        Sfrom=[handles.param.Snew1 Spartial];
        Sfrom(2).subs={from};        
        Sto=Sfrom;
        Sto(2).subs={to};
                
        [~]=builtin('subsasgn',handles.param,Sto,builtin('subsref',handles.param,Sfrom));   
        
        [~]=builtin('subsasgn',handles.param,Sfrom(1:end-1),rmfield(builtin('subsref',handles.param,Sfrom(1:end-1)),Sfrom(end).subs));   
        
        if ~any(field.hierarchyLevels==to)
            field.hierarchyLevels(end+1)=to;
        end
        field.hierarchyLevels=unique(field.hierarchyLevels);

        field.hierarchyLevels(field.hierarchyLevels==from)=[];
        handles.param.flatStruct(field_index)=field;
        
        new_view_level=to;
        if(nargin==3) %if we deleted the value, well switch to the toplevel
            new_view_level=max(field.hierarchyLevels);
        end

        if top_involved        
            %reload everything
            setListboxes(handles,field.identifier, handles.param.structNames{new_view_level});
        else
            setStructListbox(handles,field.identifier,handles.param.structNames{new_view_level});
        end

    end

    
% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over structListbox.
function structListbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to structListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%this is a bit dangerous, as someone might have made changes to the
%params class in the meantime.....
handles.param.flatStruct=handles.flatStruct;
handles.param.flatStructIdMap=containers.Map({handles.flatStruct.identifier},1:length(handles.flatStruct));
