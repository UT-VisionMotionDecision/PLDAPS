function outStruct=createRigPrefs()

    %to we already have current settings?
    a=getpref('pldaps');
    if ~isempty(a)
        warning('you already have a pldaps setting, be sure not no lose those seetings....');
    end
    
    %to we have and old PLDAPS Version setting?
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
            fromOldPrefs.spikeserver=b.spikeserver;
            fromOldPrefs.spikeserver.use=true;
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
            
            %keyboard codes
            if isfield(odv,'kb')
                fromOldPrefs.keyboard.codes=odv.kb;
            end
            
        end
    end
    

    warning('Loading default values, any previous prefs and also prefs from the old PLDAPS (dv struct). Move things you want as a rig default to the pldapsRifPrefs (doule click in the right value list on the value you want to move and select to move it to pldapsRigPrefs) when done, click done. Then type return on the command line.');
    p=pldaps('test','nothing',fromOldPrefs)
    p.defaultParameters.view
    keyboard
    
    %save old prefs
    if ~isempty(a)
        sfn=['Saved_pldaps_prefs' sprintf('_%i', clock)];
        warning(['saving old pladps prefs to ' sfn]);
        save(sfn, 'a');
    end
     
    %make changes in the viewer and press done. move things you want in the
    %pldapsRifPrefs to there (doule click in the right value list on the value you want to move and select to move it to pldapsRigPrefs)
    %when done, click 'done'
    %you can skip this or in addition to this, change parameters by editing
    %p.defaultParameters, this is noy a struct, but behaved similarly...
    
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