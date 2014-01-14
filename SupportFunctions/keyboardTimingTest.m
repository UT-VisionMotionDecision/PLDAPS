% This is a test script for comparing KbQueueCheck and KbCheck from the
% psychtoolbox. On average KbQueueCheck can be more than ten times faster than
% KbCheck, but it cannot be run with multiple keyboards. Select which to
% use in your trial functions depending on you need. For high frame rate
% stimulus displays, KbQueueCheck may be necessary. For displaying on fMRI
% where the button box is separate from the experimenter keyboard, KbCheck
% may be necessary. 

% 08/2013 jma wrote it
% 01/2013 jly update and wrote some comments

iShouldKeepGoing = true;

loopCount = 1;
KbCheckTime = 0;
GetMouseCheckTime = 0;
KbQueueCheckTime = 0;
maxQCheckTime = 0;
maxKbCheckTime = 0;
maxGetMouseCheckTime = 0;

quitKey = KbName('q');

KbQueueCreate(-1);
KbQueueStart()
KbQueueFlush()
disp('Polling keyboard using both KbCheckQueue and KbCheck.  Press q to quit');
ListenChar(2);
while iShouldKeepGoing
           
    timeBefore=GetSecs();
    [keyIsDown keySecs keyCode]=KbCheck;
    timeAfter =GetSecs();
    
    
    KbCheckTime = KbCheckTime+(timeAfter-timeBefore);
    if (timeAfter-timeBefore)>maxKbCheckTime;
        maxKbCheckTime = (timeAfter-timeBefore);
    end
    
    timeBefore=GetSecs();
    [pressedQ firstPressQ]=KbQueueCheck();
    timeAfter =GetSecs();

    KbQueueCheckTime = KbQueueCheckTime+(timeAfter-timeBefore);
    if (timeAfter-timeBefore)>maxQCheckTime;
        maxQCheckTime = (timeAfter-timeBefore);
    end
    
    timeBefore=GetSecs();    
    [event, nremaining] = KbEventGet();
    timeAfter =GetSecs();
    
    timeBefore=GetSecs();
    GetMouse;
    timeAfter =GetSecs();
    GetMouseCheckTime=GetMouseCheckTime+(timeAfter-timeBefore);

    if (timeAfter-timeBefore)>maxGetMouseCheckTime;
        maxGetMouseCheckTime = (timeAfter-timeBefore);
    end
    
    if loopCount>1000
        iShouldKeepGoing = false;
    end
    
    if pressedQ
        disp(['KbQueue found: ' KbName(firstPressQ) ' KbCheck found: ' KbName(keyCode) ]);
        
        if(firstPressQ(quitKey))
            break;
        end
    end

    if keyIsDown
        disp(['KbQueue found: ' KbName(firstPressQ) ' KbCheck found: ' KbName(keyCode) ]);        
        if(keyCode(quitKey))
            break;
        end
    end
    
WaitSecs(.016);
loopCount = loopCount+1;
end
ListenChar(0);
KbQueueStop();
KbQueueFlush();


disp(['KbCheck took an average of: ' num2str(1000*KbCheckTime/loopCount) ' ms per call, and a max time of: ' num2str(1000*maxKbCheckTime) ])
disp(['KbQueueCheck took an average of: ' num2str(1000*KbQueueCheckTime/loopCount) ' ms per call, and a max time of: ' num2str(1000*maxQCheckTime)])

disp(['GetMouse took an average of: ' num2str(1000*GetMouseCheckTime/loopCount) ' ms per call, and a max time of: ' num2str(1000*maxQCheckTime)])

