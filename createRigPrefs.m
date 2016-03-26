function outStruct=createRigPrefs(additionalSettings)
%CreateRigPrefspdsBeginExperimentcreate preferences stored as matlab preferences
% outStruct=createRigPrefs(additionalSettings) allows to create and change
% existing rig parameters stored iin the matlab preference 'pldaps'.
% These setting override the default parameters of the pldaps class.
% The optional additionalSettings will be loeaded into a a higher hierarchy
% level from where it can be copied over in the parameters viwer.
% outStruct is the final struct of settings that were also stored in the
% matlab preference system.

    %to we already have current settings?
    a=getpref('pldaps');
    if ~isempty(a)
        warning('you already have a pldaps setting, be sure not no lose those seetings....');
    end
    
    %do we have and old PLDAPS Version setting?
    b=getpref('PLDAPS');
    %yes? ok, let's try to copy some info over
    if ~isempty(b)
        fromOldPrefs=struct;
        if isfield(b,'datadir')
            fromOldPrefs.pldaps.dirs.data=b.datadir;
        end
        if isfield(b,'wavfiles')
            fromOldPrefs.pldaps.wavfiles.data=b.wavfiles;
        end
        if isfield(b,'spikeserver')
            fromOldPrefs.plexon.spikeserver=b.spikeserver;
            fromOldPrefs.plexon.spikeserver.use=true;
        end
        if isfield(b,'rig') %this has the old dv struct
            odv=load(b.rig);
            odv=odv.dv;
            if isfield(odv,'pass')
                fromOldPrefs.pldaps.pass=odv.pass;
            end
            
            %datapixx
            if isfield(odv,'dp')
                fromOldPrefs.datapixx=odv.dp;
            end
            if isfield(odv,'useDatapixxbool')
                fromOldPrefs.datapixx.use=odv.useDatapixxbool;
            end
            
            if isfield(odv,'useMouse')
                fromOldPrefs.mouse.use=odv.useMouse;
            end
            
            if isfield(odv,'useEyelink')
                fromOldPrefs.eyelink.use=odv.useEyelink;
            end
            
            %display
            if isfield(odv,'disp')
                fromOldPrefs.display=odv.disp;
                
                if isfield(odv.disp,'display')
                    fromOldPrefs.display=rmfield(fromOldPrefs.display,'display');
                    fromOldPrefs.display.displayName=odv.disp.display;
                end
            end
            
%             %keyboard codes
%             if isfield(odv,'kb')
%                 fromOldPrefs.keyboard.codes=odv.kb;
%             end
            
        end
    else
        fromOldPrefs=[];
    end
    
    p=pldaps('test','nothing');
    if isstruct(fromOldPrefs)
        p.defaultParameters.addLevels({fromOldPrefs}, {'PLDAPS 3 Prefs'})
    end
    if nargin>0
        p.defaultParameters.addLevels({additionalSettings}, {'additional Settings'})
    end
    
    p.defaultParameters
    p.defaultParameters.view
    warning('Loaded default values, any previous preferences and also preferences from the PLDAPS3.');
    fprintf(2,[...
        '\n\nINSTRUCTIONS for setting local rig preferences:\n'...
        'The local default settings are stored in pldapsRigPrefs. There\n'...
        'are two ways to change the value stored in pldapsRigPrefs for a\n'...
        'given parameter:'...
        '\n\nOption 1: Move the value you want as rig default to \n'...
        'pldapsRigPrefs from another set of preferences (e.g. \n'...
        'SessionParameters, PLDAPS3).  Double click on the value and \n'...
        'select move to pldapsRigPrefs from the drop down menu.'...
        '\n\nOption 2: Define the values yourself by clicking on the value\n'...
        'field of pldapsRigPrefs for the parameter you want to change. Type\n'...
        'the new value in the box below (you will have to physically click\n'...
        'on this box with the mouse) and press enter.'...
        '\n\nVERY IMPORTANT for both options: When you are done adding new \n' ...
        'parameters, type dbcont into the command line and press enter. \n'...
        '(If you forget to type dbcont, createRigPrefs will forget the \n'...
        'new rig prefs).\n\n']);
        

    %save old prefs
    if ~isempty(a)
        sfn=['Saved_pldaps_prefs' sprintf('_%i', clock)];
        warning(['saving old pladps prefs to ' sfn]);
        save(sfn, 'a');
    end
     
    keyboard
    %make changes in the viewer and press done. move things you want in the
    %pldapsRifPrefs to there (doule click in the right value list on the value you want to move and select to move it to pldapsRigPrefs)
    %when done, click 'done'
    %you can skip this or in addition to this, change parameters by editing
    %p.defaultParameters, this is not a struct, but behaves similarly...
    %if you do not want to use the viewer but want to add parameters
    %manually, you should call 
    %p.defaultParameters.setLevels([1 2]);
    %now, to ensure that you are adding the values at the correct hierarchy
    %level
    
    %once all is set, call
    p.defaultParameters.setLevels(2);
    outStruct=p.defaultParameters.mergeToSingleStruct();
    
    fn=fieldnames(outStruct);
    outStructc=struct2cell(outStruct);
    
    if ~isempty(a)
        rmpref('pldaps'); %remove current
    end
    setpref('pldaps',fn(:),outStructc); %set new
    
    warning('Done. saved the output of this function as new pldaps prefs');
end