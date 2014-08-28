function [PDS, dv, comboFilename] = pdsCombineTempFiles(TEMPdir, filename)
%   function [PDS, dv, comboFilename] = pdsCombineTempFiles(TEMPdir, filename)
%
% The function can be used in case a PDS session aborted unexpectedly and 
% the PDS & dv were not saved.
% The function loads temp PDS files that are saved into the TEMP folder 
% after every PDS trial and combines them into a single PDS structure, as 
% would be expected were it to be saved appropriately...
% * YOU MUST SAVE THE COMBINED PDS/dv YOURSELF!
%
% Input:
%   TEMPdir     - the directory name for TEMP files (usually '/data/TEMP')
%   filename    - filename for the temp files (e.g. pat20140422newsomedots1128)
%
% Output:
%   PDS             - the combined PDS struct
%   dv              - the combined dv struct
%   comboFilename   - the combined filename ending with the str 'combined'
%                     for quick n' easy saving.



%% GET FILES:

% get all files that match filename:
files = dir([TEMPdir '/' filename '*']);    

if isempty(files)
    fprintf('\n\nSorry there were no files under that name.\nYou probably screwed up\n\n');
    return
else
    fprintf(['\n\nGoing to salvage all PDS files named:\n\n     '  filename '\n\nand raise PDS from the ashes of the dead\n\n']);
end

%% ONE FOR ALL & ALL FOR ONE:

% fancy waitbar:
h = waitbar(0, 'Please wait while raising PDS from ashes of the dead');

%get all PDS files for requested dataset:
for t = 1:length(files)
    C{t} = files(t).name;
end

% sort files in numeric (rather than alphabetical) order:
sfiles = sort_nat(C);

% copy the PDStemp for the current file into the main PDS struct:
for t = 1:length(sfiles)   
    load([TEMPdir '/' sfiles{t}], '-mat')
    
    flds = fields(PDStemp);
    for f = 1:length(flds)    
        % cells go here:
        if iscell(PDStemp.(flds{f}))
            PDS.(flds{f}){t}    = PDStemp.(flds{f}){1};
         
        % numerics go here:    
        elseif isnumeric(PDStemp.(flds{f})) || islogical(PDStemp.(flds{f}))       
             if length(PDStemp.(flds{f}))==1
                PDS.(flds{f})(t)      = PDStemp.(flds{f});
             else
                if size(PDStemp.(flds{f}),1) > 1                % if it's in the form of colum per trial
                    PDS.(flds{f})(:,t)    = PDStemp.(flds{f});
                elseif size(PDStemp.(flds{f}),2) > 1
                    PDS.(flds{f})(t,:)    = PDStemp.(flds{f});       % if there's 1 row per trial)
                end
             end      
        % structures go here and go through the same process again:
        elseif isstruct(PDStemp.(flds{f}))
 
            subflds = fields(PDStemp.(flds{f})); 
            for subf = 1:length(subflds)
                % cells go here:
                if iscell(PDStemp.(flds{f}).(subflds{subf}))
                    PDS.(flds{f}).(subflds{subf}){t}    = PDStemp.(flds{f}).(subflds{subf}){1};
                 
                % numerics go here:
                elseif isnumeric(PDStemp.(flds{f}).(subflds{subf}))
                     if length(PDStemp.(flds{f}).(subflds{subf}))==1
                        PDS.(flds{f}).(subflds{subf})(t)      = PDStemp.(flds{f}).(subflds{subf});
                     else
                        if size(PDStemp.(flds{f}).(subflds{subf}),1) > 1
                            PDS.(flds{f}).(subflds{subf})(:,t)    = PDStemp.(flds{f}).(subflds{subf});
                        elseif size(PDStemp.(flds{f}).(subflds{subf}),2) > 1
                            PDS.(flds{f}).(subflds{subf})      = PDStemp.(flds{f}).(subflds{subf});
                        end
                     end
                     
                elseif isstruct(PDStemp.(flds{f}).(subflds{subf}))
                    fprintf('\n\n\nWTF?! Yet ANOTHER struct?! no way fuck this im done\n\n\n\n');
                end
            end 
        end
    end
% update waitbar every 20 files:
if mod(t,20)==0
    waitbar(t/length(sfiles), h)
end

end
  
delete(h)
        
% save([TEMPdir '/' filename(1:end-4) '_SALVAGED.PDS'], 'PDS', 'dv', '-mat')

fprintf(['\n\n' filename ' is alive! ALIIIIIVE! \n']);


comboFilename = [filename 'combo.PDS'];


