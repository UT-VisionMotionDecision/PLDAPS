function [pa, trialLevelMatrix] = recreateParams(PDS)

    conditionTrials=cellfun(@(x) textscan(x,'Trial%dParameters'),PDS.conditionNames);
    conditionTrials=[conditionTrials{:}];
    if any(conditionTrials~=1:length(PDS.conditions))
        error('conditions not sorted');
    end

    afterpauseparms=cellfun(@(x) textscan(x,'PauseAfterTrial%dParameters'),PDS.initialParameterNames);
    isafterpauseparm=~cellfun(@isempty,afterpauseparms);

    %and sepereate the pre experiment levels
    preLevels=find(~isafterpauseparm);
%     preOffset=length(PDS.initialParameterNames);
    %from the pause levels and get the trials after which they where defined
%     afterPauseLevels=find(isafterpauseparm);
    afterPauseTrials=[afterpauseparms{isafterpauseparm}];

    initial=params(PDS.initialParameters(preLevels),PDS.initialParameterNames(preLevels));
    initial=initial.mergeToSingleStruct;

    if ~isfield(PDS,'analysis')
        PDS.analysis=cell(size(PDS.data));
    end

    dN=cellfun(@(x) sprintf('data%i',x),num2cell(1:length(PDS.data)),'UniformOutput',false);
    aN=cellfun(@(x) sprintf('analysis%i',x),num2cell(1:length(PDS.analysis)),'UniformOutput',false);

    instructs=[{initial} PDS.initialParameters(isafterpauseparm) PDS.conditions PDS.data PDS.analysis];
    pa=params(instructs,['initialParameters' PDS.initialParameterNames(isafterpauseparm) PDS.conditionNames dN aN]);

%                 functionLevels=[preLevels afterPauseLevels(iTrial>afterPauseTrials) preOffset+find(conditionTrials==iTrial)];

%                 p.data.setLevels(functionLevels);

%                 p.trial.addLevels(PDS.data,cellfun(@(x) sprintf('Data%i',x),num2cell(1:length(PDS.data)),'UniformOutput',false),0)

%     hierarchy={'initial', 'afterpauseparms', 'conditions', 'data', 'analysis'};
%     static=1;
%     afterTrial=3;
%     perTrial=3;
%     type={static,afterTrial,perTrial,perTrial,perTrial};

    trialLevelMatrix=zeros(length(instructs), length(PDS.data));
    trialLevelMatrix(1,:)=true; %static
    %missing afterpause trials
    trialLevelMatrix((2+sum(isafterpauseparm)):end,:)=[eye(length(PDS.data)); eye(length(PDS.data)); eye(length(PDS.data))];

    for k=1:length(afterPauseTrials);
        trialLevelMatrix(1+k,afterPauseTrials(k)+1:end)=true;
    end

    trialLevelMatrix=~~trialLevelMatrix;