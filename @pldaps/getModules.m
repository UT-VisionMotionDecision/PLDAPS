function [modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p)


    %add a requested Order: from -Inf allways first to 0 Default to after
    %deafult to Inf: last (or NaN: even later), then reorder modules by sorting these
    modules=fieldnames(p.trial);
    modules(cellfun(@(x) ~isstruct(p.trial.(x)),modules))=[]; %remove non struct candidates
    modules(cellfun(@(x) ~isfield(p.trial.(x),'stateFunction'),modules))=[]; %remove candidates without a stateFucntion specified
    modules(cellfun(@(x) (~isfield(p.trial.(x),'use') || ~p.trial.(x).use ),modules))=[]; %remove modules not activated
    
    moduleOrder=double(cellfun(@(x) isfield(p.trial.(x).stateFunction,'order'),modules));
    moduleOrder(find(moduleOrder))=cellfun(@(x) p.trial.(x).stateFunction.order, modules(find(moduleOrder)));
    [moduleOrder,so]=sort(moduleOrder);
    modules=modules(so);
    
    moduleLocationInputs=cellfun(@(x) (isfield(p.trial.(x).stateFunction,'acceptsLocationInput') && p.trial.(x).stateFunction.acceptsLocationInput),modules); %does the function accept the thirn input to specifiy where to save the data?
    
    moduleFunctionHandles=cellfun(@(x) str2func(p.trial.(x).stateFunction.name), modules, 'UniformOutput', false); 
%     moduleRequestedStates=cellfun(@(x) (p.trial.(x).stateFunction.requestedStates), modules, 'UniformOutput', false);
     
    availiableStates=fieldnames(p.trial.pldaps.trialStates);
    %a little too long, ok, so if requestedStates is not defined, or .all
    %is true, we will call it for all states. Otherwise it will only call
    %the ones defined and true.
    moduleRequestedStates=cellfun(@(x) cellfun(@(y) (~isfield(p.trial.(y).stateFunction,'requestedStates') || (isfield(p.trial.(y).stateFunction.requestedStates,'all') && p.trial.(y).stateFunction.requestedStates.all) || (isfield(p.trial.(y).stateFunction.requestedStates,x) && p.trial.(y).stateFunction.requestedStates.(x))), modules), availiableStates, 'UniformOutput', false);
    
    
    if isfield(p.trial.pldaps,'trialFunction') && ~isempty(p.trial.pldaps.trialFunction);
        modules{end+1}='stimulus';
        moduleFunctionHandles{end+1}=str2func(p.trial.pldaps.trialFunction);
        for iState=1:length(moduleRequestedStates)
            moduleRequestedStates{iState}(end+1)=true;
        end
        moduleOrder(end+1)=NaN;
        moduleLocationInputs(end+1)=false;
    end
    moduleRequestedStates=cellfun(@(x) reshape(x,1,numel(x)), moduleRequestedStates, 'UniformOutput', false);
    moduleRequestedStates=cell2struct(moduleRequestedStates,availiableStates);