function p = setup(p,scan)
%pds.git.setup   setup the keyboard queue
%
% Setup universal Mac/PC keyboard and keynames
% set scan to 1 if using button box in scanner, otherwise, leave empty.
% output: kb. a struct with all keys (e.g. kb.pKey = 'p')
%
% p = pds.keyboard.setup(p)
%
% T.Czuba 6-4-2008
% ktz updated the function description Apr2013
% jk 2014 adapted to work with version 4.1

if nargin < 2
    scan = 0;
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


if scan && isMac
    
    devices = getDevices;
    
    if isempty(devices.keyInputExternal);
        
        kb.devint =devices.keyInputInternal(1);
        
        kb.dev = devices.keyInputInternal(end);
        
        disp('internal keyboard');
        
        disp(kb.devint)
        
        disp('no external devices');
        
    elseif isempty(devices.keyInputInternal);
        
        kb.devint =devices.keyInputExternal(1);
        
        kb.dev = devices.keyInputExternal(end);
        
        disp('external keyboard');
        
        disp(kb.devint)
        
        disp('no internal key devices');
        
    else
        
        kb.devint = devices.keyInputInternal(1);
        
        kb.dev = devices.keyInputExternal(1);
        
        disp('internal keyboard');
        
        disp(kb.devint)
        
        disp('external keyboard');
        
        disp(kb.dev)
        
    end
end
p.trial.keyboard.codes=kb;

pds.keyboard.clearBuffer(p);

 [~, firstPress]=KbQueueCheck();
 
 p.trial.keyboard.nCodes=length(firstPress);

% [kb.keyIsDown, ~, kb.keyCode] = KbCheck(-1);

end