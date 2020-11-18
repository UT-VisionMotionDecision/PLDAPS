function runStateforModules(p, state, modules, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs)

%using cellfun might be slower than a for loop and does not guarantee
%execution in order of the arrays, so for loop seems like proper solution here. Ideally it would be
%     cellfun(@(x) x(p, p.trial.pldaps.trialStates.(state)), modules(moduleRequestedStates.(state)));

% tmpModules = moduleRequestedStates.(state);
% for iModule = find(tmpModules(:))'
stateNumber = p.trial.pldaps.trialStates.(state); % avoid repetetive digging into params object 

for iModule = moduleRequestedStates.(state)
        moduleFunctionHandles{iModule}(p, stateNumber, modules{iModule});
end