function p = checkNumKeys(p)
% function p = pds.keyboard.checkNumKeys(p)
% 
% Detect instantaneous state of number keys and report their values
% - Avoids repetative digging through each keycode individually within modules/functions
%
% NOTE:
% - .numKey values are derivative of the ongoing keyboard values that are recorded
%   within p.trial.keyboard [.samples, .pressedSamples, etc].
%   Thus these are momentary values. and **are not [intended to be] recorded**
%   Use them in code/modules, but expect to derive them in your analysis.
%   (e.g. using this code as example)
%   
%
% 2019-12-xx  TBC  Wrote it. Not a great implementation, but it works

% This is so gross...there has to be a better way!
keyIdx = p.trial.keyboard.numKeys.codes;    % created by pds.keyboard.setup.m
%           [ KbName('1!'), KbName('1');...
%             KbName('2@'), KbName('2');...
%             KbName('3#'), KbName('3');...
%             KbName('4$'), KbName('4');...
%             KbName('5%'), KbName('5');...
%             KbName('6^'), KbName('6');...
%             KbName('7&'), KbName('7');...
%             KbName('8*'), KbName('8');...
%             KbName('9('), KbName('9');...
%             KbName('0)'), KbName('0')];
        
        
%% Blagh!!
...why is it so maximally krufty to interact with this damn keyboard sampling struct?!?!
    
pressed = p.trial.keyboard.firstPressQ(keyIdx); %reshape( max(p.trial.keyboard.lastPressSamples(keyIdx,:),[],2), size(keyIdx));% > max(p.trial.keyboard.lastReleaseSamples(keySets,:),[],2);

pressed = pressed>0;
p.trial.keyboard.numKeys.logical = pressed; %| p.trial.keyboard.numKeys.logical; % momentary, or aggregate? (e.g.  pressed+p.trial.keyboard.numKeys.logical)
p.trial.keyboard.numKeys.pressed = p.trial.keyboard.numKeys.numVals(pressed);


end % main function