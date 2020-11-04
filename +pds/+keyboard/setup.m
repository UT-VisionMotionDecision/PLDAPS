function p = setup(p, devIdx)
%p = pds.keyboard.setup(p, devIdx)
% 
% Setup universal Mac/PC keyboard and keynames
% 
% INPUTS:
% [p]       Pldaps object/structure
% [devIdx]  Keyboard device index. (def==-1, first detected keyboard device)
%           - Can use getDevices.m to determine your devIdx, then (optionally)
%           store in rig defaults as .keyboard.devIds
% 
% OUTPUTS:
% [p]       Pldpas object/structure with initialized p.trial.keyboard struct 
%
%
% 2008-04-06  T.Czuba  Wrote it
% 2013-04-00  ktz   Updated the function description
% 2014-00-00  jk    Adapted to work with version 4.1
% 2017-06-27  tbc   Removed KbQueue dependency on clearbuffer.m for initialization
%                   Replaced depreciated 'scan' input with device index [devIdx]
% 2020-10-07  tbc   devIdx set using pldaps defaults,
%                   added modifier key (modKeys) & number key (numKeys) substructs to .keyboard
% 

% Be explicit about what device we're polling
%       (...subsequent KbQueueXxxx calls need to respect this too, but we gotta start somewhere)
if nargin < 2 || isempty(devIdx)
    devIdx = p.trial.keyboard.devIdx; % PTB/PLDAPS default==-1
end

    
KbName('UnifyKeyNames');
kb.oneKey = KbName('1!');
kb.twoKey = KbName('2@');
kb.thrKey = KbName('3#');
kb.forKey = KbName('4$');
kb.fivKey = KbName('5%');
kb.sixKey = KbName('6^');
kb.svnKey = KbName('7&');
kb.eitKey = KbName('8*');
kb.ninKey = KbName('9(');
kb.zerKey = KbName('0)');
kb.minKey = KbName('-_');
kb.qKey = KbName('q');
kb.wKey = KbName('w');
kb.eKey = KbName('e');
kb.rKey = KbName('r');
kb.tKey = KbName('t');
kb.yKey = KbName('y');
kb.uKey = KbName('u');
kb.iKey = KbName('i');
kb.oKey = KbName('o');
kb.pKey = KbName('p');
kb.aKey = KbName('a');
kb.sKey = KbName('s');
kb.dKey = KbName('d');
kb.fKey = KbName('f');
kb.gKey = KbName('g');
kb.hKey = KbName('h');
kb.jKey = KbName('j');
kb.kKey = KbName('k');
kb.lKey = KbName('l');
kb.zKey = KbName('z');
kb.xKey = KbName('x');
kb.cKey = KbName('c');
kb.vKey = KbName('v');
kb.bKey = KbName('b');
kb.nKey = KbName('n');
kb.mKey = KbName('m');

kb.escKey = KbName('ESCAPE');
kb.spaceKey = KbName('space');
%% Arrows
kb.Rarrow = KbName('RightArrow');
kb.Larrow = KbName('LeftArrow');
kb.Uarrow = KbName('UpArrow');
kb.Darrow = KbName('DownArrow');

%% Modifiers
kb.Lctrl = KbName('LeftControl');
kb.Lalt = KbName('LeftAlt');
kb.Lshift = KbName('LeftShift');
kb.Rctrl = KbName('RightControl');
kb.Ralt = KbName('RightAlt');
kb.Rshift = KbName('RightShift');

%% keypad
kb.KPoneKey = KbName('1');
kb.KPtwoKey = KbName('2');
kb.KPthrKey = KbName('3');
kb.KPforKey = KbName('4');
kb.KPfivKey = KbName('5');
kb.KPsixKey = KbName('6');
kb.KPsvnKey = KbName('7');
kb.KPeitKey = KbName('8');
kb.KPninKey = KbName('9');
kb.KPzerKey = KbName('0');
kb.plusKey  = KbName('=+');
kb.minusKey = KbName('-_');


p.trial.keyboard.codes=kb;


%% Modifier keys [ctrl, alt, shift]
if IsLinux
    % sidestep duplicate key mappings on Linux    
    altR = find(contains( KbName('keynameslinux'), 'Alt_R'));
    modKeys = [KbName('LeftControl'),KbName('RightControl'); KbName('LeftAlt'), altR; KbName('LeftShift'),KbName('RightShift')]';
else
    modKeys = [KbName('LeftControl'),KbName('RightControl'); KbName('LeftAlt'),KbName('RightAlt'); KbName('LeftShift'),KbName('RightShift')]';
end
p.trial.keyboard.modKeys = struct('codes',modKeys,'ctrl',0,'alt',0,'shift',0);


%% Num keys
% Specifically poll number keys
% - Updated in:     pds.keyboard.checkNumKeys
% - Used by:    pldapsDefaultTrial.m >> pds.keyboard.getQueue >> pds.keyboard.checkNumKeys

%   key codes as: [top-row, keypad]
numVals = [1:9,0;  1:9,0]';
numKeys = [ KbName('1!'), KbName('1');...
            KbName('2@'), KbName('2');...
            KbName('3#'), KbName('3');...
            KbName('4$'), KbName('4');...
            KbName('5%'), KbName('5');...
            KbName('6^'), KbName('6');...
            KbName('7&'), KbName('7');...
            KbName('8*'), KbName('8');...
            KbName('9('), KbName('9');...
            KbName('0)'), KbName('0')];
%           == reshape(KbName({'1!','2@','3#','4$','5%','6^','7&','8*','9(','0)',  '1','2','3','4','5','6','7','8','9','0'}), [10,2]);

% output as substruct
p.trial.keyboard.numKeys = struct('codes',numKeys, 'numVals',numVals, 'pressed',[], 'logical',false(size(numKeys)));    %  , 'first',[], 'last',[]);


%% Start Kb Queue
% Establish the queue
KbQueueCreate(devIdx);
% Start collecting keystrokes
KbQueueStart(devIdx);


%% initialize outputs
% Populate output fields & info
[p.trial.keyboard.pressedQ, p.trial.keyboard.firstPressQ] = KbQueueCheck(devIdx);
p.trial.keyboard.nCodes = length(p.trial.keyboard.firstPressQ);
% If devIdx input, ensure pldaps struct is consistent
p.trial.keyboard.devIdx = devIdx;

% standard trial setup & cleanup to prevent extraneous empty fields in saved data struct (see pldapsDefaultTrial.m)
pds.keyboard.trialSetup(p);

% now clear them
% ...annoyingly, this is not the same as initializing as empty: size(this)=[1,0]; size([])=[0,0]
p.trial.keyboard.samplesTimes(:,p.trial.keyboard.samples+1:end) = [];
p.trial.keyboard.samplesFrames(:,p.trial.keyboard.samples+1:end) = [];
p.trial.keyboard.pressedSamples(:,p.trial.keyboard.samples+1:end) = [];
p.trial.keyboard.firstPressSamples(:,p.trial.keyboard.samples+1:end) = [];
p.trial.keyboard.firstReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];
p.trial.keyboard.lastPressSamples(:,p.trial.keyboard.samples+1:end) = [];
p.trial.keyboard.lastReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];
        

end %main function
