function getFiles()
%pds.eyelink.getFiles    transfer from from eyelink to this machine
%
% jk wrote it 2014
prevDir=cd;

p=pldaps;
datadir = p.trial.pldaps.dirs.data;

cd(datadir)

[files, dirs]=uigetfile('*.PDS','Choose PDS files to get EDF files for','MultiSelect','on');

nfiles=length(files);
if(~iscell(files))
    nfiles=1;
end

Eyelink('Initialize');

for j=1:nfiles
   
    if(nfiles==1)
        file=files;
    else
        file=files{j};
    end
    load(fullfile(dirs,file), '-mat');
    
%     for k=1:length(PDS.session.time)
%        result=Eyelink('Receivefile', datestr(PDS.session.time{k}, 'mmddHHMM'), fullfile(dirs,[file(1:end-3) 'edf']));
       result=Eyelink('Receivefile', PDS.initialParameters{4}.eyelink.edfFile, fullfile(dirs,[file(1:end-3) 'edf']));
       if(result==-1)
          warning('pds:EyelinkGetFiles', ['receiving ' PDS.initialParameters{4}.eyelink.edfFile '.edf for pds file ' file ' failed!']) 
       else
           display([num2str(j) ' out of ' num2str(nfiles) ' files received: ' PDS.initialParameters{4}.eyelink.edfFile '.edf for pds file ' file '.'])
       end
        
%     end
cd(prevDir);
end


