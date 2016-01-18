function runStateforModules(p,state,modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs)

for iModule=find(moduleRequestedStates.(state))
    if moduleLocationInputs(iModule)
        moduleFunctionHandles{iModule}(p,p.trial.pldaps.trialStates.(state),modules{iModule}); 
    else
        moduleFunctionHandles{iModule}(p,p.trial.pldaps.trialStates.(state)); 
    end
end