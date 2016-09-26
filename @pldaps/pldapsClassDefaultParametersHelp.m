function h=pldapsClassDefaultParametersHelp(h)
 if nargin<1
	h=cell(0,2);
 end
h=[h 
{
'.', 'root, i.e. p.trial or p.defaultParameters';
'.behavior' ,'behavioral control parameters';
'.behavior.reward' ,' reward';
 '.behavior.reward.defaultAmount'  ,'Default amount of reward.\nAmount of reward in units of the reward sysrtem being used';

'.datapixx' ,' VPixx device control (Datapixx, ProPixx, VIEWPixx)';
 '.datapixx.enablePropixxCeilingMount' ,'ProPixx: enableCeilingMount (flip image vertically)';
 '.datapixx.enablePropixxRearProjection','ProPixx: enableRearProjection (flip image horizontally)';
 '.datapixx.LogOnsetTimestampLevel' ,'Get and Store a the time each frame arrived at the VPixx device.\nSee help PsychDataPixx; and search for LogOnsetTimestamps for detail. Data is stored in datapixx.timestamplog at the end of the experiment. Fields per Frame are: [Datapixx time, PTB time, Flip Number]. See help PsychDataPixx; and search for GetTimestampLog for detail';
 '.datapixx.use' ,'enable control of VPixx devices';
 '.datapixx.useAsEyepos' ,'use Datapixx adc inputs as eye position.\nSets fields p.trial.eyeX and .eyeY each frame during frameUpdate. See .datapixx.adc.';
 '.datapixx.useForReward' ,'use Datapixx to set...for a given duration....';

'.datapixx.adc' ,'continuously collect and store adc data from Datapixx.\nTimestamps for each sample are stored in datapixx.adc.dataSampleTime. The number of collect samples is in datapixx.adc.dataSampleCount';
 '.datapixx.adc.bufferAddress','typically left empty.\nsee Datapixx(''SetAdcSchedule?''). specifies the start of the RAM buffer which should hold the acquired data inside the Datapixx. Use ReadAdcBuffer to upload the acquired data from this address after calling StartAdcSchedule.';
 '.datapixx.adc.channelGains','Apply a gain to collected data.\nscalar or vector (1xnchannels) of gains applied to each channel: gains*(data+offset)';
 '.datapixx.adc.channelMapping' ,'Speicifed where to store the collected data.\nWhen channelMapping is a string, the same field will be used all channel. When channelMapping is a cell of strings, each string is the location of for that channel. Repetitions of the same location cause channel of the nth mention, to be store as the nth row. E.g. {''eye.X'', ''eye.Y'' ''joystick.XYs'' ''joystick.XYs''} would store data channel 1 and 2 in eye.X and eye.Y respetivelt and channels 3 and 4 in joystick.XYs(1:2,:)';
 '.datapixx.adc.channelModes','Defines the referencing of the channel.\nsee Datapixx(''SetAdcSchedule?''). The second row of the matrix indicates the differential voltage references for each acquired channel. The reference is selected using a code in the range 0-3. Code 0 is used when no differential subtraction is required during acquisition. All analog inputs are referenced to ground, also known as single-ended acquisition. Code 1 implements fully differential inputs, subtracting the adjacent channel''s voltage before acquiring (eg: acquiring ADC0 with code = 1 would subtract the ADC1 voltage from the ADC0 voltage, writing the result to the acquisition buffer). When using this mode, data is typically acquired only on the even channels, effectively halving the number of available channel. Code 2 implements a differential input referenced to the REF0 analog input (see the Datapixx user manual for pinouts). This has the benefits of high-impedance differential inputs, without having to sacrifice half of the channels as with fully differential input. Code 3 implements a differential input referenced to the REF1 analog input. It is possible to use different codes for different analog channels in a single acquisition schedule. For example ADC0 and ADC1 could be acquired single-ended while ADC2 is referenced to ADC3, and ADC4/5/6/7 could be referenced to REF0. It is also possible to pass only a single row of ADC channels to channelList. In this case, all of the ADC channels will be acquired single-ended.';
 '.datapixx.adc.channelOffsets','Apply an offset to collected data.\nscalar or vector (1xnchannels) of offsets applied to each channel: gains*(data+offset)';
 '.datapixx.adc.channels','List of channels to collect data from.\nsee Datapixx(''SetAdcSchedule?'')';
 '.datapixx.adc.maxSamples','maximum number of samples to collect\n0 means no upper bound.';
 '.datapixx.adc.numBufferFrames','maximum number of samples to store in datapixx memory.';
 '.datapixx.adc.srate','samples rate in Hz';
 '.datapixx.adc.startDelay','delay until beginning of recording.';
 '.datapixx.adc.XEyeposChannel','if datapixx.useAsEyepos=true, use this channel set eyeX';
 '.datapixx.adc.YEyeposChannel','if datapixx.useAsEyepos=true, use this channel set eyeY';

'.datapixx.GetPreciseTime','set interntal paramers for PsychDatapixx(''GetPreciseTime'').\nThis is highly recommened to speed up inter trial interval. see pldapsSyncTests, PsychDatapixx(''GetPreciseTime?'')';
 '.datapixx.GetPreciseTime.maxDuration','maximum duration in seconds to wait for a good estimate';
 '.datapixx.GetPreciseTime.optMinwinThreshold','Minimum Threshold that defines a good estimate to end before maxDuration';
 '.datapixx.GetPreciseTime.syncmode','syncmode. accepted values are 1,2,3';

'.display' ,'specify options for the screen. ';
 '.display.bgColor' ,'background color. Can be changed during trial';
 '.display.colorclamp' ,'clampt colors to [0-1] range. Typically not necessary';
 '.display.destinationFactorNew','Blending mode';
 '.display.displayName' ,' a name for your screen';
 '.display.forceLinearGamma' ,'force a linear gamma table at the end of screen initiation.\nThis was a workaround for a Datapixx bug and should not be needed any more';
 '.display.heightcm',' height of the visible screen in cm';
 '.display.normalizeColor' ,'use colors in [0-1] range. Often implied by other setting anyway';
 '.display.screenSize','size of the window to create pixels in, leave empty for fullscreen';
 '.display.scrnNum','screen numer for fullscreen display';
 '.display.sourceFactorNew','Blending mode';
 '.display.stereoFlip','check before use if supported';
 '.display.stereoMode','check before use if supported';
 '.display.switchOverlayCLUTs' ,'switch olverlay colors bewteen experimentor and subject view';
 '.display.useOverlay' ,'create an overlay pointer.\nIf no Hardware (datapixx) of dedicated software overlay is enabled';
 '.display.viewdist' ,'screend distance to the observer';
 '.display.widthcm' ,' width  of the visible screen in cm';

'.display.movie' ,'optinal create of videos, typically used during replay';
 '.display.movie.create' ,'toggle movie creation';
 '.display.movie.dir' ,'directory to store the movie.\nLeave empty to use same location as PDS file';
 '.display.movie.file','file name. Leave empty to use same file base as PDS file';
 '.display.movie.frameRate','frame rate of the movie.\nLeave empty to use the srceens frame rate. If frameRate is lower than screens frame rate, only every mod(..) frame will be captured';
 '.display.movie.height','height of the movie.\nleave ampty to use window size';
 '.display.movie.options','encoding parameters';
 '.display.movie.width','width of the movie.\nleave ampty to use window size';

'.eyelink' ,'Eyelink specific parameters\nmodule to interact with eyelink and collect eyelink data';
 '.eyelink.buffereventlength','don''t change.\nNumber of fields for each event';
 '.eyelink.buffersamplelength','don''t change.\nNumber of fields for each sample';
 '.eyelink.calibration_matrix','calibration matrix when using raw (uncalibrated) Data';
 '.eyelink.collectQueue' ,'collect and store each sample recorded during trials\n(as opposed to one per screen frame)';
 '.eyelink.custom_calibration','don''t use.\ntoggle custom calibrations';
 '.eyelink.custom_calibrationScale','don''t use.\ntoggle custom calibrations scale';
 '.eyelink.saveEDF','togge downloading of the EDF file directly after the experiment.\nUsuall better to do this after the session using pds.eyelink.getFiles';
 '.eyelink.use','use the eyelink moduke';
 '.eyelink.useAsEyepos','toggle use of eyelink to set eyeX and eyeY';
 '.eyelink.useRawData','toggle use of raw (uncalibrated) Data.\nsee eyelink.calibration_matrix';

'.git' ,'Control use of git\ntry to save current state of the PLDAPS git repository used to run the experiment';
 '.git.use' ,'toggle of of git module';

'.mouse','configure how mouse data should be handled';
 '.mouse.use' ,'collect and store mouse positions';
 '.mouse.useAsEyepos' ,'toggle use of mouse to set eyeX and eyeY';

'.newEraSyringePump' ,'module to control a newEra syringe pump via USB';
 '.newEraSyringePump.alarmMode' ,'create an alarm when stalled';
 '.newEraSyringePump.allowNewDiameter','allow changing of the syringe diameter';
 '.newEraSyringePump.diameter','syringe diameter in mm';
 '.newEraSyringePump.lowNoiseMode','use low noise mode (never noticed a difference)';
 '.newEraSyringePump.port','USB emulated serial port of the pump';
 '.newEraSyringePump.rate','flow rate';
 '.newEraSyringePump.triggerMode','Trigger mode for manual triggers using the pumps TTL input.\nT2 is rising endge. T is fallsing edge. Check manual for more.';
 '.newEraSyringePump.use' ,'toggle use of newEraSyringePump module';
 '.newEraSyringePump.volumeUnits','units for dispensing. ML or UL';

'.pldaps' ,'pldaps core parameters';
 '.pldaps.experimentAfterTrialsFunction', 'a function to be called after each trial.\nAt this stage trialCleanUpandSave is already called and data of the last trial is stored in p.data. Any changes to parameters will overrule previous parameters not defined in a condition struct.Can only be used when .pldaps.useModularStateFunctions is true.';
 '.pldaps.eyeposMovAv','average the eyeposition (.eyeX and .eyeY) over this many samples.\nThis is done by the source (e.g. eyelink, datapixx, mouse) and not controlled by pldaps directly';
 '.pldaps.finish','Number of trials to run. can be changed dynamically';
 '.pldaps.goodtrial','indicator whether the trial was good. Not used by pldaps itself';
 '.pldaps.iTrial','trial number. cannot be changed by the user';
 '.pldaps.maxPriority','Switch to PTB to maxpriority during the trial? See MaxPriority(''?'')';
 '.pldaps.maxTrialLength','Maximum duration of a trial in seconds. Used to allocate memory.\nYou need to use this to also assign p.trial.pldaps.maxFrames = p.trial.pldaps.maxTrialLength*p.trial.display.frate;';
 '.pldaps.nosave','disables saving of data when true. see .pldaps.save for more control';
 '.pldaps.pass','indicator of behavior (i.e. fixations) should always be assumed to be good.';
 '.pldaps.quit','control expeiment during a trial.\n1: go into a pause mode immediately and allow paraneters to be changed for future trials. Any changes to parameters will overrule previous parameters not defined in a condition struct. 2: end experiment immediately. If you want to end the experiment to end after the regular end of the trial, set .pldaps.finish=.pldaps.iTrial instead. When using pldapsDefaultTrialFunction, pressing p sets quit to 1 (pause) and q sets quit to 2 (end experiment)';
 '.pldaps.trialMasterFunction','function to be called to run a single Trial.\nThis function will call other user functions at different states. pldaps has two builtin master functions: runTrial and runModularTrial. runModularTrial is backward compatible to runTrial, but allows using multiple state functions in one trial. See pldaps.runModularTrial for details. runModularTrial requite .pldaps.useModularStateFunctions to be true. Users can also define any other function accepting a pldaps object as input if desired';
 '.pldaps.useFileGUI','use a GUI to specify the output file.\nif false, pldaps will automatically name the output in the format subjectYYYYMMDDExperimentSetupFilenameHHMM.PDS';
 '.pldaps.useModularStateFunctions','use modular state functions, see pldaps.runModularTrial, pldaps.getModules, pldaps.runStateforModules';

'.pldaps.dirs','directories used by pldaps';
 '.pldaps.dirs.data','data directory.\nPLDAPS will not create this directory for you. Inside, create a folder names TEMP. If it does not exist, pldaps will create it on first use with a warning.';
 '.pldaps.dirs.wavfiles','directory for sound files\ndirectory of sound files to load at the beginning of the experiment';

'.pldaps.draw','configure pldaps'' builtin drawing options';
'.pldaps.draw.cursor','control drawing of the mouse cursor';
 '.pldaps.draw.cursor.use','enable drawing of the mouse cursor.\nCurrently uses p.trial.stimulus.eyeW ti specify the pixel width and p.trial.display.clut.cursor to specify the color';

'.pldaps.draw.eyepos','control drawing of the eye position';
 '.pldaps.draw.eyepos.use','enable drawing of the eye position.\nCurrently uses p.trial.stimulus.eyeW ti specify the pixel width and p.trial.display.clut.eyepos to specify the color';

'.pldaps.draw.framerate','control drawing of a framerate history to see framedrops.\nIf drawn, expected frame interval (ifi) is marked as a solid black line, 0 and 2*ifi as dashed lines. Actual ifi as red dots.';
 '.pldaps.draw.framerate.location','location (XY) of the plot in degrees of visual angle.';
 '.pldaps.draw.framerate.nSeconds','number of seconds to show the history for';
 '.pldaps.draw.framerate.show','draw the framerate. need use to be enabled as well';
 '.pldaps.draw.framerate.size','size (XY) of the plot in degrees of visual angle.';
 '.pldaps.draw.framerate.use','set to true to collect data needed to show framerate.\nSet show to use at times you want draw it.';

'.pldaps.draw.grid','control drawing of a grid\ndraw a grid, with short lines very degree and long lines every 5 degrees.';
 '.pldaps.draw.grid.use','enable drawing of the grid';

'.pldaps.draw.photodiode','control drawing of a flashing photodiode square.\nTypically not used';
 '.pldaps.draw.photodiode.everyXFrames','will be shown every nth frame';
 '.pldaps.draw.photodiode.location','location of the square as an index\n1-4 for the different corners of the screen';
 '.pldaps.draw.photodiode.use','enable drawing the photodione square';

'.pldaps.pause','control pausing behavior of pldaps';
 '.pldaps.pause.preExperiment','pause before experiment starts\nif true, pdlaps will pause before the first trial, allowing to change parameters or to calibrate e.g. an eyetracker';
 '.pldaps.pause.type','Only type 1 is currently tested.\nType 1: go into debugger mode for command line control. Type 2: A Pause loop with defined keyboard command to execute commands.';

'.pldaps.save','control how pldaps saves data';
 '.pldaps.save.initialParametersMerged','save merged initial parameters\nsave a merged version of all parameters before the first trial?';
 '.pldaps.save.mergedData','Save merged data\nBy default pldaps only saves changes to the trial struct in .data. When mergedData is enabled, the complete content of p.trial is saved to p.data. This can cause significantly larger files';
 '.pldaps.save.trialTempfiles','save temp files with the data from each trial?';
 '.pldaps.save.v73','save as matlab version v73?\nThis is slower but necessary for very large data files but also helpful and faster for partial reading of only some parameters of the file';

'.pldaps.trialStates','The states that an experiment runs through\nThe states are colled in ascending order of the parameter value. Negative values are for parameters called outside of frames.';
 '.pldaps.trialStates.experimentAfterTrials', 'called after each trial.\nAt this stage trialCleanUpandSave is already called and data of the last trial is stored in p.data. Any changes to parameters will overrule previous parameters not defined in a condition struct. Can only be used when .pldaps.useModularStateFunctions is true.';
 '.pldaps.trialStates.experimentCleanUp','called at the end of the experiment.\n just before saving the data. This is the time to close connections for any modules. Can only be used when .pldaps.useModularStateFunctions is true.';
 '.pldaps.trialStates.experimentPostOpenScreen','called after the screen was opened.\n before the first trial starts. Any parameters that depend on e.g. screen size can be set here. Can only be used when .pldaps.useModularStateFunctions is true.';
 '.pldaps.trialStates.experimentPreOpenScreen','called before the screen is opened.\nAny settings that would change how the screen is created could be set here. Can only be used when .pldaps.useModularStateFunctions is true.';
 '.pldaps.trialStates.frameDraw','called every frame for drawing command.\nThere should be no computations that need to be stored here, just drawing commands. This is important to allow for an easier reperation for potential later replays of stimuli.';
 '.pldaps.trialStates.frameDrawingFinished','called every frame after drawing.\nUsually only used by pldapsDefaultTrialFuncion';
 '.pldaps.trialStates.frameDrawTimecritical','disabled';
 '.pldaps.trialStates.frameFlip','called every frame to flip the buffers.\nUsually only used by pldapsDefaultTrialFuncion';
 '.pldaps.trialStates.frameIdlePostDraw','diabled';
 '.pldaps.trialStates.frameIdlePreLastDraw','diabled';
 '.pldaps.trialStates.framePrepareDrawing','called every frame to prepare drawing.\nThis is where all computations should go, but no drawing commands. And no retrieval of information that other modules might rely on. This is important to allow for an easier reperation for potential later replays of stimuli.';
 '.pldaps.trialStates.frameUpdate','called every frame to update input.\nThis is where devices should retrieve new data and store them. No other computations should occur here to make potential replay scenarios easier.';
 '.pldaps.trialStates.trialCleanUpandSave','called at the end of the trial.\nbefore data is moved to .data. This is a good time to remove data that should not be stored and also potentrially alter/manage future(!) conditions. If you change past conditions, you run the risk of corrupting your data!';
 '.pldaps.trialStates.trialPrepare','called before each trial for synchronization\nrun any (synchronization) commands that should be close to close to the first frame';
 '.pldaps.trialStates.trialSetup','called before each trial for data allocation.\nallocate data for the trial, setup and compute all information that should not be computed on the fly.';

'.plexon','interact with plexon MAP or Omniplex';
'.plexon.spikeserver','configure our plexon spike server.\n(Also has NAN drive depth collection prepared but not yet activated)';
 '.plexon.spikeserver.continuous','true if you want data to be sent when it arrived\n(as opposed to sending it oppon request)';
 '.plexon.spikeserver.eventsonly','true if you only want to receive events, not spikes';
 '.plexon.spikeserver.remoteip','IP of the plexon machine';
 '.plexon.spikeserver.remoteport','Port set on the plexon machine''s spikeserver';
 '.plexon.spikeserver.selfip','This machine''s IP';
 '.plexon.spikeserver.selfport','The port this machine should use';
 '.plexon.spikeserver.use','toggle use of our plexon spikeserver';

'.session','parameters from this experiment';
 '.session.experimentFile','the experiment setup file used to set up the experiment';

'.sound','contol sound playback';
 '.sound.deviceid','PsychPortAudio deviceid, empty for default';
 '.sound.use','toogle use of sound';
 '.sound.useForReward','toogle playing a sound for reward\n(must be names ''reward'' in the pldaps.dirs.wavefiles directory';
}];
end