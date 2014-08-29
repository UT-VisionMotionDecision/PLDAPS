PLDAPS 4.1
==========

PLexon DAtapixx PSychtoolbox - Neurophysiology experiment toolbox for MATLAB

Version 4.1 incorporates some larger changes that will break previous code. 
The new concept attempts to preserve the flexibility of PLDAPS while allowing 
to reduce code multiplication when desired. 
It is still possible to copy code, but it provides a framework that makes it unneccessary. 
This has the advantage that bug do not have to be fixed in many many files but just once.
It also reduced the required knowledge to start the first experiemnts as a new user.
Of course over time, any user should be familiar with all code, but learning may be easier if
a new experiment can be setup without this knowledge.

Framework:
%% pldaps
The core is a class called pldaps.

When a pldaps is created, it will load default parameters from different sources 
into a fieled called defaultParameters. This is again a class (named @params) 
that can handle a hierarchy of parameters.
Importantly, pldaps is a handle class, which allows reduction of some memory allocation.

    %Specifically, assume you have an object p of type pldaps
    p=pldaps;
    %Any changes made to a copy of p, will also effect p, as they are in fact using the same memory.
    p2=p;
    p2.defaultParameters.newParameter='see I told you so';
    display(p.defaultParameters.newParameter);
    %notice that I created a new Parameter newParameter in object p2, but 
    %but now you can also acess itusing p, because p2 und p are identical.

creating a pldaps class:
The pldaps contructor accepts the following inputs, all are optional:
    1. a subject identifier (string)
    2. a function name or handle that sets up all experiement parameters
    3. a struct with changes to the defaultParameters, this is usefull for debugging
As long as the inputs are classifiable, the order is not important, otherwise 
for the remaining unclassified inputs the above order is assumed.

    %Specifically when both subject and the function are strings the input must be
    p=pldaps('subject','functionName', debugStruct);% or
    p=pldaps('subject', debugStruct, 'functionName'); % or
    p=pldaps(debugStruct,'subject', functionName');
    %but not
    p=pldaps('functionName','subject', debugStruct);
    %but when suing a handle, this is ok:
    p=pldaps(@functionName,'subject', debugStruct);
    %using a handle also enables tab completion for the function name, so I'd recomment using a handle

now the defaultParameters are loaded, but the experiment isn't starting yet, not has
the provided experiment function been called yet.

%% pldaps.run
pldaps.run implements an experiment, that can interface with a number of external 
hardware devices as well and will call a trial function each trial.

Of course there is no need to use this, if you wanted to run your own experiment script,
but in that case there might not be any benefit of using this version of pldaps.

once the Psychtoolbox screen is created
pldaps.run will call the experiment function provided in the constructor.
This function 
- can define the functions being called each trial (later), 
- define any further colors you want to use in a datapixx dual clut scenario
- create anything that should be created before the first trial starts, 
- define any stimulus parameters that a true for all trials in p.defaultParameters
- and should add a cell of structs to p.conditions that that holds the changes in parameters from therse defaults for _each_trial_

note: in later versions, p.conditions might actually only hold information about certain conditions and another field the info of what conditions to use in each trial.

%% pldaps.runTrial
unless another function is specified in the parameters as the 
p.defaultParameters.pldaps.trialMasterFunction
it defaults to dv.defaultParameters.pldaps.trialMasterFunction="runTrial";

This is a generic trial function that takes case of the correct course of a trial.
It will run through different stages for the trial and in a loop for each frame
run through stages from frameUpdate to frameFlip.

For each stage, instead of doing something itself, it calles another function, defined in
p.defaultParameters.pldaps.trialFunction that take the pldaps class and a numerical state number as input.

This is the only function that needs to be implemented by the use to take care of the drawing of the stimulus.

%% pldapsDefaultTrialFunction
all basic features of pldaps from flipping the buffers to drawing the eye position of the experimentor screen are
implemented in a function called pldapsDefaultTrialFunction
To make use of these, this function must simply be called by your trialFunction.


%% putting it all together
ok, now you will run your first experiment and work your way back from the trialFunction
to the core of pldaps.

got into the folder tutorial or have in in your path
    %now load some settings that should allow to run pldaps in a small screen for now
    > load settingsStruct;
    %next creat a pldaps object and specify to use plain.m as the experiment file
    %set the subject to 'test'  and pass the struct we just loaded
    p=pldaps(@plain,'test',settingsStruct)
    %now you have a pldaps object, to start the experiment, call
    p.run
    %shoud should now see a gray screen with a white grid in degrees of visual angle
    %when you move the cursor of the mouse, it will be drawn at a corresponding position in cyan on that screen
    %the screen is full gay for a short time every 5 seconds
    
now lets step back and understand why we see what we see:
first load a new, fresh version of the object
    p=pldaps(@plain,'test',settingsStruct)

    now type in
    p.trial or
    p.defaultParameters
    this has all settings loaded, and as long as we are not in a trial p.trial points to p.defaultParameters
    
    you will see a list of fieldnames
    
    I'll list them here
        spikeserver  <- setting for communicating with plexon omniplex system
        display     <- all display parameters
        datapixx    <-parameters for datapixx, including options to record analog data (datapixx.adc)
        keyboard    <-keybord codes for the keys
        mouse       <-parameters for the mouse, curently only whether to use is as an eyeposition
        eyelink     <- all parameters to control eyelink
        pldaps      <- 'internal' parameters, including what drawing pldaps does itself
        session     <- subject and file name, etc
        sound       <- play sounds?
        git         <- control whether git should be used to store revisions and changes from the used PLDAPS repository

    %ok, now first look at
    p.trial.pldaps.draw, you will noctice that
    p.trial.pldaps.draw.grid.use==true and
    p.trial.pldaps.draw.eyepos.use==true

If you want you can play around with these option and run it again...

now open up the file we provided to setup the experiemnt
    edit plain
    %When it is called by pldaps.run at the beginning of the experiment, only the pldaps object is being passed
    %Thus, first look at the section if nargin==1, that in being excecuted in that case
    %For some things for function correctly we have to call
    
    %pdsDefaultTrialStructure(p) and  defaultTrialVariables(p)
    %This is something that still needs cleaning up, but it won't harm having it here
    %Next the function that should be called for all the drawing and calculations of your stimulus is defined by

    %p.defaultParameters.pldaps.trialFunction='plain';   
    %I.e. in this example case, we use the same function to setup the experiment parameters and to calculate the stimulus
    %this is typically not the case later, when you have one stimulus file and several experiments that you define that use the sae stimulus code
    %If you do not want to use the default trial function that is called for each Trial and manages the frames, etc, you can also define a
    % %dv.defaultParameters.pldaps.trialMasterFunction='runTrial';
    %be we won't do that here.
    %next we define  p.trial.pldaps.maxTrialLength and  p.trial.pldaps.maxFrames
    %these are parameters that are also used by the runTrial function to allocate some data
    %finnally we set load a cell of structs into the p.conditions property
    %for before each trial, the properties defined here will be merged with the default properties that werde defined before. and in this function
    %if you want to, set a breakpoint and exlpore the stack of functions

    %ok, now everything is setup,
    %set a breakpoint in plain and start the experiment
    %You will notice a few things
    %a) plain gets called even before the first frames with state set to dv.trial.pldaps.trialStates.trialSetup or dv.trial.pldaps.trialStates.trialPrepare
    %b) within a frame plian also gets called multiple times with different states. check out all states:
        %dv.trial.pldaps.trialStates
        %(the Idle states are currently disabled, but could be reactivated if needed)
    %c) plain calles 
        %pldapsDefaultTrialFunction(p,state)
        %for each state. This means that all the default behavior will get executed,
        %this includes fetching data from eyelink,datapixx,current mouse position, checking the keyboard (frameUpdate)
        %but also drawing of the grid and eyeposition if the parameters are set to use.
        %If you wanted to leave out this defaultBehavior and do it all by yourself, that is possible,
        %but currently a couple of things defined and allocated by ldapsDefaultTrialFunction are also used by the runTrial
        %function, so we should either clean this up, or you call the pldapsDefaultTrialFunction(p,state) for the required states
    
     %ok, now work with the debugger a bit to get a first idea of what's going on.

%% setting up rig specifig default settings
that you know the basics set up a pldaps system on your machine and run an experiment. 
Then 


%% Understanding all parameters
Here all parameters should get explained, along with where they are being used


