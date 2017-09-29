function nitenite
% Put Propixx projector to sleep or wake up.
% No inputs; auto-selects based on current state.
% 
% 2017-07-25  TBC  Wrote it.
% 

if ~Datapixx('IsReady')
    Datapixx('Open');
end

n = now;

if Datapixx('IsPropixxAwake')
    msg = 'Propixx going to sleep.';
    tmp = Datapixx('GetTempFarenheit');
    Datapixx('SetPropixxSleep');
    Datapixx('RegWrRd');

else
    msg = 'Propixx is waking up.';
    Datapixx('SetPropixxAwake');
    Datapixx('RegWrRd');
    tmp = Datapixx('GetTempFarenheit');
    
end

fprintf(['\n\n\t',repmat('_-',1,19),'\n'])
fprintf(2, '\t------\t%s\t------\n', msg)
fprintf('\t------\t%s\t------\n',   datestr(n, 'dddd  yyyy-mm-dd'))
fprintf('\t------\t   %s\t\t------\n', datestr(n, 'HH:MM:SS PM'))
fprintf('\t------\tCurrent Temp: %2.1f F\t------\n', tmp)
fprintf(['\t',repmat('_-',1,19),'\n\n'])
