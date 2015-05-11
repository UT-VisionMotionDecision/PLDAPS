function [dat, pos]= nanread(filename)
% res=regexp(a,'----------- (?<day>\d{1,2})\s+(?<month>\w+)\s+(?<year>\d+)\s+(?<hour>\d+):(?<minute>\d+):(?<second>\d+)\s-----------\s', 'names')
% 
% 
% res=regexp(a,'----------- (?<day>\d{1,2})\s+(?<month>\w+)\s+(?<year>\d+)\s+(?<hour>\d+):(?<minute>\d+):(?<second>\d+)\s-----------\s+(?<driveNr>\w+)\s+(?<drivePos>\d+.\d+)\s+', 'names')
% 
% res=regexp(a,'----------- (?<day>\d{1,2})\s+(?<month>\w+)\s+(?<year>\d+)\s+(?<hour>\d+):(?<minute>\d+):(?<second>\d+)\s-----------\s+(?<driveNr>\w+)\s+(?<drivePos>\d+.\d+)\s+', 'names')
% lastlength=1;
saveNANDrivePositions();
a=fileread(filename);
% newlength=length(a);
% a=a(lastlength:end);
[dates, dateInds]=regexp(a,'----------- (?<day>\d{1,2})\s+(?<month>\w+)\s+(?<year>\d+)\s+(?<hour>\d+):(?<minute>\d+):(?<second>\d+)\s-----------\s+\w_', 'names','start');
[drivespositions, drivesposInds]=regexp(a,'(?<driveNr>\w_)\s+(?<drivePos>-?\d+.\d{3,3})\s+\d?\s*', 'names','start');
if ~isempty(dates)
    dat=dates(end);
    pos=drivespositions(drivesposInds>dateInds(end));
else
    dat=[];
    pos=[];
end

% fid=fopen(filename,'w');
% fwrite(fid,[]);
% fclose(fid);
% lastlength=newlength;