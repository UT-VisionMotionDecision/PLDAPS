function runStateforModules(p,state,modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs)

%using cellfun might be slower than a for loop and does not guaranty
%execution in order of the arrays. Not sure if save. Ideally it would be
%     cellfun(@(x) x(p,p.trial.pldaps.trialStates.(state)),modules(moduleRequestedStates.(state)));

tmpModules=moduleRequestedStates.(state);
for iModule=find(tmpModules(:))'
    if moduleLocationInputs(iModule)
        moduleFunctionHandles{iModule}(p,p.trial.pldaps.trialStates.(state),modules{iModule});
    else
        moduleFunctionHandles{iModule}(p,p.trial.pldaps.trialStates.(state));
    end
end