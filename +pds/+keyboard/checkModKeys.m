function p = checkModKeys(p)
% function pds.keyboard.checkModKeys(p)
% 
% Update state of modifier keys [ctrl, alt, shift]
% 
% ...agnostic of left/right key, but could easily be extended
%
% 2019-07-30  TBC  Wrote it.

% This is so gross...there has to be a better way!
keySets = [KbName('LeftControl'),KbName('RightControl'); KbName('LeftAlt'),KbName('RightAlt'); KbName('LeftShift'),KbName('RightShift')]';
isheld = max(p.trial.keyboard.lastPressSamples(keySets,:),[],2) > max(p.trial.keyboard.lastReleaseSamples(keySets,:),[],2);

isheld = max(reshape(isheld, [2,3]));
keyStr = {'ctrl','alt','shift'};
for i = 1:3
    p.trial.keyboard.modKeys.(keyStr{i}) = isheld(i);
end