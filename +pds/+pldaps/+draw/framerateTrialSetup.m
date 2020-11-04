function framerateTrialSetup(p)
% function pds.pldaps.draw.framerateTrialSetup(p)
% 
% Initialize fields for rendering frame rate history plot
% onto the overlay screen (a legacy debug feature....ymmv)
% - direct copy-paste of Jonas-era code
% 
% 2020-10-12 TBC  Functionified.
% 


p.trial.pldaps.draw.framerate.nFrames=round(p.trial.pldaps.draw.framerate.nSeconds/p.trial.display.ifi);
p.trial.pldaps.draw.framerate.data=zeros(p.trial.pldaps.draw.framerate.nFrames,1); %holds the data
sf.startPos=round(p.trial.display.w2px'.*p.trial.pldaps.draw.framerate.location + [p.trial.display.pWidth/2 p.trial.display.pHeight/2]);
sf.size=p.trial.display.w2px'.*p.trial.pldaps.draw.framerate.size;
sf.window=p.trial.display.overlayptr;
sf.xlims=[1 p.trial.pldaps.draw.framerate.nFrames];
sf.ylims=  [0 2*p.trial.display.ifi];
sf.linetype='-';

p.trial.pldaps.draw.framerate.sf=sf;

end %main function