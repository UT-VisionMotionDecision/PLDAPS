function p = setup(p, devIdx)
%pds.git.setup   setup the keyboard queue
%
% Setup universal Mac/PC keyboard and keynames
% set scan to 1 if using button box in scanner, otherwise, leave empty.
% output: kb. a struct with all keys (e.g. kb.pKey = 'p')
%
% p = pds.keyboard.setup(p)
%
% 2008-04-06  T.Czuba  Wrote it
% 2013-04-00  ktz   Updated the function description
% 2014-00-00  jk    Adapted to work with version 4.1
% 2017-06-27  tbc   Removed KbQueue dependency on clearbuffer.m for initialization
%                   Replaced depreciated 'scan' input with device index [devIdx]
% 

% Be explicit about what device we're polling
%       (...subsequent KbQueueXxxx calls need to do this too, but we gotta start somewhere)
if nargin < 2 || isempty(devIdx)
    devIdx = -1; % PTB default
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
kb.Rarrow = KbName('RightArrow');
kb.Larrow = KbName('LeftArrow');
kb.Uarrow = KbName('UpArrow');
kb.Darrow = KbName('DownArrow');
kb.Lctrl = KbName('LeftControl');
kb.Lalt = KbName('LeftAlt');
kb.return = KbName('return');
%Numeric keypad
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


% Establish the queue
KbQueueCreate(devIdx);
% Start collecting keystrokes
KbQueueStart(devIdx);

% Populate output fields & info
[p.trial.keyboard.pressedQ, p.trial.keyboard.firstPressQ] = KbQueueCheck(devIdx);
p.trial.keyboard.nCodes = length(p.trial.keyboard.firstPressQ);
p.trial.keyboard.devIdx = devIdx;


end