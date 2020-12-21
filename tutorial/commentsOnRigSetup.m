% commentsOnRigSetup.m
% 
% Brief notes & comments on PLDAPS rig setup
%   --T.Czuba  Dec. 2020
% 

% This code not intended for wholesale execution.
% Read through for info and execute code from individual sections as needed.
return 


%% General tips & tricks
% ----------------------------------------------------------------
% To effectively pause experiment execution, PLDAPS code regularly [ab]uses Matlab's built-in
% 'keyboard' function to break-out into a debug state & handover control to the user.
% 
% To return from this state, the user is generally prompted to type  `dbcont` into the
% command window to resume. ...over time this will become tedious.
% 
% A handy solution is to set a custom keyboard shortcut for Matlab's "Run or Continue Execution"
% action.
% - Matlab Preferences >> Keyboard >> Shortcuts
% - search for action "contain"
% - add a new shortcut to:   control-shift-x
% 
% ...while [dangerously] close to ctrl-c, this shortcut is easy to do with one hand & has the
% same key configuration across OSes.  --TBC


%% Setting Rig Prefs
% ----------------------------------------------------------------
%% Retrieve the PLDAPS settings struct [pss] of your own current rig prefs with
pss = createRigPrefs;

% as instructed, must enter `dbcont` in the command window to cleanly exit/return
% from the createRigPrefs [pseudo]GUI


%% Apply saved/new rig prefs with
% Included sample prefs are helpful for code development on a MacbookPro:
% - disables datapixx & eyelink
% - tells PLDAPS to use mouse as 'eye' position
% - opens PTB screen as a small inset on primary screen
%   - adds an extra PsychImaging task to deal with Retina Display resolution
%   - brightens background color (better demo clarity)
%   - defines physical display dimensions that result in reasonable ppd given MBP screen
pss = load(rigPrefs_MacbookDev);
createRigPrefs(pss);

%  Aside from current state of unreliable PTB timing on MacOS, running in
%  such a non-full-screen window will always degrade performance beyond
%  'experimental grade', but should suffice for general code development.
%  


%% Coding on Macbook Pro in 2020
% ----------------------------------------------------------------
% I've written the following into my standard startup.m function to identify & apply
% overall machine specific settings (i.e. things not only PLDAPS specific):

% Which machine is this?
[~, hn] = system('hostname'); hn(end) = []; % trim npc

% machine specific 
switch hn
    case {'identifyYourMBP', 'anotherMach'}
        % Macbook Pro
        machFlags = {'skipSyncTests'};
        
    case 'yaddayadda'
        machFlags = {'yadda'};
        
    otherwise
        machFlags = {};
end    

%% Do your setup stuff
% ...I like to also give Matlab's initial random number generator state a good 'spin' here,
% but do whatever is safe/expected for your lab & conditions --TBC

%     %% Setup random number generator & some default behaviors
%     s = RandStream.create('mt19937ar','seed',sum(100*clock));
%     
%     if verLessThan('matlab','7.14')
%         RandStream.setDefaultStream(s); 
%     else
%         % make up your damn mind, Matlab!
%         RandStream.setGlobalStream(s);
%     end

%% Apply machine specific startup
% Warn about possible PTB sync errors on MacOS
if contains(machFlags, 'skipSyncTests')
    fprintf(2, '\n%s  WARNING  %s\n', repmat('!',[1,35]), repmat('!',[1,35]))
    fprintf(2, '!!!\tHardware/OS with broken sync issues detected.\n!!!\tExecute the following code to disable sync tests & warnings:\n')
    fprintf('\tScreen(''Preference'', ''SkipSyncTests'', 2); Screen(''Preference'', ''Verbosity'', 1);\n')
    fprintf(2, '!!!\tBUT know that your stimuli won''t be "research grade" with these settings!!!\n')
    fprintf(2, '%s  WARNING  %s\n\n', repmat('!',[1,35]), repmat('!',[1,35]))
    % Nope: Screen preferences set w/in startup.m do not stick.  --TBC 2018-02
    % evalin('base', 'Screen(''Preference'', ''SkipSyncTests'', 2); Screen(''Preference'', ''Verbosity'', 1);')
end

% ----------------------------------------------------------------

