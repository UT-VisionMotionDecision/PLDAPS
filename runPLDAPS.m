function [PDS,dv] = runPLDAPS(subj, condition, newsession)
% [PDS, dv] = runPLDAPS(subject, condition, [newsession = 1])
% PLDAPS (Plexon Datapixx PsychToolbox) version 3
%       runPLDAPS is a wrapper for calling PLDAPS condition files
%           It opens PsychImaging pipeline and initializes datapixx for
%           dual color lookup tables. Everything else must be in the
%           condition file and trial function. See PLDAPScheck.m for
%           explanation.  IMPORTANT: edit setupPLDAPSenv.m and
%           makeRigConfigFile.m before running. 
% INPUTS:
%       subj [string]       - initials for subject
%       condition [string]  - name of matlab function that runs trials
%                           - you must have the condition file in your path 
%       newsession [0 or 1] - if 1, start new PDS. 0 load old PDS (defaults
%       to 1)
%       [brackets] indicate optional variables and their default values

% 10/2011 jly wrote it (modified from letsgorun.m)
% 12/2013 jly reboot. updated to version 3 format.

% Tested to run with Psychtoolbox
% 3.0.11 - Flavor: beta - Corresponds to SVN Revision 4331
% For more info visit:
% https://github.com/Psychtoolbox-3/Psychtoolbox-3

PDS = []; 
dv  = [];

if nargin<3
    newsession = true; 
    if nargin <2
        condition = [];
        if nargin < 1
            help runPLDAPS
            return
        end
    end
end

try
    % Build input struct
    opts = [];
    opts.subj       = subj;
    opts.condition  = condition;
    opts.newsession = newsession;
    
    %% Setup and File management
    % Setup filename and data directories. Add rig specific parameters (set in
    % setupPLDAPS) and then run the condition file which sets up experimental
    % parameters.
    
    if isempty(getpref('PLDAPS'))
        
        disp('No PLDAPS preferences set on this rig... see setupPLDAPSenv.m')
        help setupPLDAPS
        return
        
    else
        Prefs = getpref('PLDAPS');
        
        % get code base
        if isfield(Prefs, 'base') && ~isempty(Prefs.base)
            base = getpref('PLDAPS','base');
        else
            error('Code base directory is not set. see setupPLDAPSenv.m')
        end
        
        % get Data directory
        if isfield(Prefs, 'datadir') && ~isempty(Prefs.datadir)
            datadir = getpref('PLDAPS','datadir');
        else
            setpref('PLDAPS','datadir',fullfile(pwd,'Data'));
            disp(['Setting PLDAPS data directory preference to: ' fullfile(pwd,'Data')]);
            disp('Use the folowing command to change:');
            disp('setpref(''PLDAPS'',''datadir'',/path/to/PLDAPS/Data); ');
        end
        
        % get Rig file
        if isfield(Prefs, 'rig') && ~isempty(Prefs.rig)
            opts.rig = getpref('PLDAPS','rig');
        else
            setpref('PLDAPS','datadir',fullfile(pwd,'Data'));
            disp(['Setting PLDAPS data directory preference to: ' fullfile(pwd,'Data')]);
            disp('Use the folowing command to change:');
            disp('setpref(''PLDAPS'',''datadir'',/path/to/PLDAPS/Data); ');
        end
        
    end
    
    % setup file
    if opts.newsession
        
        if isfield(opts, 'rig')
            load(opts.rig)
        else
            error('specify rig file')
        end
        
        dv.subj = opts.subj; 
        dv.pref = Prefs; 
        
        % pick YOUR experiment's main CONDITION file-- this is where all
        % expt-specific stuff emerges from
        if isempty(opts.condition)
            [cfile, cpath] = uigetfile('*.m', 'choose condition file', [base '/CONDITION/debugcondition.m']); %#ok<NASGU>
            
            dotm = strfind(cfile, '.m');
            if ~isempty(dotm)
                cfile(dotm:end) = [];
            end
            opts.condition = cfile;
        end
        
        % generate PDS filename
        PDS = {};
        PDS.subj = opts.subj; 
        
        if ~isfield(dv, 'nosave')
            [sfile, datadir] = uiputfile('.PDS', 'initialize experiment file', fullfile(datadir, [opts.subj datestr(now, 'yyyymmdd') opts.condition datestr(now, 'HHMM') '.PDS']));
        end
        
    elseif opts.newsession == 0 % load old PDS file to continue
        [sfile, datadir] = uigetfile('*.m', 'load existing PDS file', datadir);
        load(fullfile(datadir,sfile), 'PDS', 'dv', '-mat');
        
        dv.quit = 0;
        disp(dv)
    else
        error('must input 0 or 1...')
    end
    
    
    
    dv.pref.sfile = sfile; 
    %% Open PLDAPS windows
    % Open PsychToolbox Screen
    dv.disp = pdsOpenScreen(dv.disp);
    
    % Setup PLDAPS experiment condition
    dv = feval(opts.condition, dv);
    
    % Initialize Datapixx for Dual CLUTS
    dv = pdsDatapixxInit(dv);
    

    %% Last chance to check variables
    dv  %#ok<NOPRT>
    disp('Ready to begin trials. Type return to start first trial...')
    keyboard %#ok<MCKBD>
    
    
    
    
    %% main trial loop %%
    % disable keyboard
    [PDS, dv] = pdsBeginExperiment(dv, PDS);
    ListenChar(2)
    HideCursor
    
    while dv.j <= dv.finish && dv.quit~=2
        
        if dv.quit == 0
            
            % run trial
            [PDS,dv] = feval(dv.trialFunction, PDS, dv);
            
            
           result = pdsSaveTempFile(dv,PDS);
           if ~isempty(result)
               disp(result.message)
           end
           
            dv.j = dv.j + 1;
            
        else 
            ListenChar(0);
            ShowCursor;
            keyboard %#ok<MCKBD>
            dv.quit = 0;
            ListenChar(2);
            HideCursor;
            
            
            pdsDatapixxRefresh(dv);
            
        end
        
    end
    
    % return cursor and command-line control
    ShowCursor
    ListenChar(0)
    Priority(0)
    dv = pdsEyelinkFinish(dv);
    
    if ~isfield(dv, 'nosave')
        save(fullfile(datadir, sfile),'PDS','dv','-mat')
    end
    
    
    Screen('CloseAll');
    sca
    
    
    
catch me
    sca
    
    
    % return cursor and command-line cont[rol
    ShowCursor
    ListenChar(0)
    disp(me.message)
    
    nErr = size(me.stack); 
    for iErr = 1:nErr
        fprintf('errors in %s line %d\r', me.stack(iErr).name, me.stack(iErr).line)
    end
    fprintf('\r\r')
    keyboard
%     disp([me.stack(:).name])
%     disp([me.stack(:).line])
    
    
    
    
end
