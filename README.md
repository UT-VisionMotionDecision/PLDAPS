
PLDAPS 4.2
==========

PLexon DAtapixx PSychtoolbox - Neurophysiology experiment toolbox for MATLAB

Version 4.1 incorporated some larger changes that will break previous code. 
Version 4.2 is fully compatible with 4.1 but adds a new, cleaner trial function that allows 
for a modularization of pldaps for new software components and potentially also for stimulus interactions.

In 4.1 the new concept attempts to preserve and extend the flexibility of PLDAPS while allowing 
to reduce code multiplication when desired. 
It is still possible to copy code, but it provides a framework that makes it unneccessary. 
This has the advantage that bugs do not have to be fixed in many many files but just once.
It also reduced the required knowledge to start the first experiemnts as a new user.
Of course over time, any user should be familiar with all code, but learning may be easier if
a new experiment can be setup without this knowledge.

%% before we start
- PLDAPS has only been tested on Matlab 2014b and 2015b on OSX 10.10. 
- Psychtoolbox needs to be installed
- If you are planning to use Datapixx, you should download a current version of the datapixx 
  toolbox from vpixx.com and place it in the matlab path above PTB. The toolbox provided with
  PTB tends to be outdated.
- For a recording rig, all basic testing should be done (e.g. VBLSyncTest with and without datapixx, etc)

%% get started / installation

Create a local copy of PLDAPS by cloning the git repository and select the version 4.2 branch (openreception).
In a terminal window, first go to the directory in which you want the PLDAPS directory to reside in.

    git clone https://github.com/HukLab/PLDAPS.git
    git checkout openreception

Now start Matlab and copy the function loadPLDAPS_template.m copy the function loadPLDAPS_template.
to a place in your path (e.g. your Matlab start folder), rename it to loadPLDAPS.m and edit the 'dirs' 
to include at least the path you just installed PLDAPS in. 
Now whenever you want to include PLDAPS in your path, just call
    loadPLDAPS

Framework:
%% pldaps
The core is a class called pldaps.

When a pldaps is created, it will load default parameters from different sources 
into a field called defaultParameters. This is again a class (named @params) 
that can handle a hierarchy of parameters.
Importantly, pldaps is a handle class, which allows reduction of some memory allocation. There are a couple of downsides to using handle classes (for one, it appears that storing function handles in a handle class reduces the performance.), but this appears to be the fastest easy way to be able to add data to a struct from inside a subfunction. It might be possible to go via a mex file to get real pointer behavior without the downsides of a handle class

    %Specifically, assume you have an object p of type pldaps
    p=pldaps;
    %Any changes made to a copy of p, will also effect p, as they are in fact using the same memory.
    p2=p;
    p2.defaultParameters.newParameter='I told you so';
    display(p.defaultParameters.newParameter);
    %notice that I created a new Parameter newParameter in object p2, but 
    %but now you can also access it using p, because p2 und p are identical.

creating a pldaps class:
The pldaps contructor accepts the following inputs, all are optional:
    1. a subject identifier (string)
    2. a function name or handle that sets up all experiement parameters
    3. a struct with changes to the defaultParameters, this is usefull for debugging, but could also be used to replace the function.
    4. a cell array containing a struct with parameters for each trial (this is typically set later in the fucntion you set in 2.)

As long as the inputs are classifiable, the order is not important, otherwise 
for the remaining unclassified inputs the above order is assumed.

    %Specifically when both subject and the function are strings the input must be
    p=pldaps('subject','functionName', parameterStruct);% or
    p=pldaps('subject', parameterStruct, 'functionName'); % or
    p=pldaps(parameterStruct,'subject', 'functionName');
    %but not
    p=pldaps('functionName','subject', parameterStruct);
    %but when using a handle, this is ok:
    p=pldaps(@functionName,'subject', parameterStruct);
    %using a handle also enables tab completion for the function name, so I'd recomment using a handle

now the defaultParameters are loaded, but the experiment isn't starting yet, and the provided experiment function has not been called yet.

%% pldaps.run
pldaps.run implements an experiment that can interface with a number of external 
hardware devices and will call a trial function each trial.

Of course there is no need to use this, if you wanted to run your own experiment script. But in that case there might not be any benefit of using this version of pldaps.

once the Psychtoolbox screen is created
pldaps.run will call the experiment function provided in the constructor.
This function 
- can define the functions being called each trial (later), 
- define any further colors you want to use in a datapixx dual clut scenario
- create anything that should be created before the first trial starts, 
- define any stimulus parameters that are true for all trials in p.defaultParameters
- and should add a cell of structs to p.conditions that that holds the changes in parameters from therse defaults for _each_trial_

note: in later versions, p.conditions might actually only hold information about certain conditions and another field the info of what conditions to use in each trial.
note: since the screen is already created, basic screen parameters like the screen size must be defined before the p.run is called. The background color can be changed on a frame by frame basis.

%% pldaps.runTrial
unless another function is specified in the parameters as the 
p.defaultParameters.pldaps.trialMasterFunction it defaults to p.defaultParameters.pldaps.trialMasterFunction="runTrial";
In order to harness the modular features of version 4.2 you will have to change this to
    p.defaultParameters.pldaps.trialMasterFunction="runModularTrial";
and also set
    p.trial.pldaps.useModularStateFunctions = true;

pldaps.runModularTrial is backwards compatible with pldaps.runTrial, so unless you have a case were you
have a specific reason not to use runModularTrial, it is recommented to switch to runModularTrial by
changing these two parameters in the rig settings using createRigPrefs

The following information is about pldaps.runModularTrial:
This is a generic trial function that takes care of the correct course of a trial.
It will run through different stages for the trial and in a loop for each frame
run through stages from frameUpdate to frameFlip.

For each stage, instead of doing something itself, it calles another function, defined in
p.defaultParameters.pldaps.trialFunction that takes the pldaps class and a numerical state number, as well as an optional location string (later) as input.

This is the only function that needs to be implemented by the user to take care of the drawing of the stimulus.

note: version 4.0 had a trialMasterFunction that instead took a class as a stimulus Function and had to have methods names frameUpdate to frameFlip. This is a cleaner, but might be more difficult for a matlab novice to understand. This is the reason for the change to the state function.

%% pldapsDefaultTrialFunction
all basic features of pldaps from flipping the buffers to drawing the eye position of the experimentor screen are
implemented in a function called pldapsDefaultTrialFunction
To make use of these, this function must simply be setup to be called by runModularTrial or from within your trialFunction.

The order in which the different states are run through is defined by the value of states defined in
    p.trial.pldaps.trialstates
All states with a positive value will be called for each frame in ascending order of the values.
By default, the order is: frameUpdate, framePrepareDrawing, frameDrawing, frameDrawingFinished, frameFlip.
States with nenative values are called outside of the frames of a trial.

have a look at the documentation for the states to understand what each is for:
    file://YOURPLDAPSROOT/PLDAPS/doc/Parameters/pldaps/trialStates/all.html

p=pldaps(@plain,'test', settingsStruct)
    p.run
        -> experimentPreOpenScreen
        PTB screen is opened
        -> experiment setup file is called
        -> experimentPostOpenScreen
        while p.trial.pldaps.iTrial < p.trial.pldaps.finish && p.trial.pldaps.quit~=2 
            p.trial is converted to a struct
            p.runModularTrial is called
                evaluates currently active modules once at the beginning of the trial
                -> trialSetup
                -> trialPrepare
                while ~p.trial.flagNextTrial && p.trial.pldaps.quit == 0
                    -> frameUpdate
                    -> framePrepareDrawing
                    -> frameDraw
                    -> frameDrawingFinished
                    -> frameFlip
                -> trialCleanUpandSave
            -> experimentAfterTrials (in pldaps.run) %here you can change default values in p.trial for the next trials
        -> experimentCleanUp
    
        %note that setting .pldaps.quit=2 will quit the current trial and end the experiment immediately
        %will setting p.trial.pldaps.finish= p.trial.pldaps.iTrial; will cause the experiment to end after the trial has run
       
                %use .flagNextTrial to indicate (immediate) end of trial with the next one starting immediately
                %use pldaps.quit=1 to indicate (immediate) end of trial and going into pause mode (leter)
                %use pldaps.quit=2 to indicate (immediate) end of experiment
  

%% What is a module
In PLDAPS 4.1 the was only one state function that was defined in p.trial.pldaps.trialFunction. This function was called for the different states and had to call other functions like the pldapsDefaultTrialFunction.
However this made it difficult to add new hardware and also put limits in the flexibility of using stimuli.
In PLDAPS 4.2 you can define many (independent) function to be called for each state.
You do this by definding a field statefunction in a subfield on pldaps
e.g.
settingsStruct.myModule.stateFunction.name='TheNameOfYourModulesStatefunctionFile';
settingsStruct.myModule.use=true;

Now, if pldaps(@plain,'test', settingsStruct) is created and you call 
    p.run
the function TheNameOfYourModulesStatefunctionFile will get called with each of the states described above.
You should design any new stateFunctions to accept a third input parameter: 
    function TheNameOfYourModulesStatefunctionFile(p,state,name)
and all variables and data from that statefunction should typically then be stored under
p.trial.(name).
Where the variable naeme is defined by the name of the subfield that holds the stateFunction parameter,
e.g. in out case
p.trial.(myModule).

However to use this name, you have tell PLDAPS that your stateFunction can accept this third input
settingsStruct.myModule.stateFunction.name='TheNameOfYourModulesStatefunctionFile';
settingsStruct.myModule.use=true;
settingsStruct.myModule.stateFunction.acceptsLocationInput=true;

If there are multiple stateFunctions, the order in which they are called if defined by the field .order.
This means a modules are called in the order of [-Inf....-1,0,1,...Inf,NaN]
settingsStruct.myModule.stateFunction.name='TheNameOfYourModulesStatefunctionFile';
settingsStruct.myModule.use=true;
settingsStruct.myModule.stateFunction.acceptsLocationInput=true;
settingsStruct.myModule.stateFunction.order=0; %default is 0

to reduce the number of unneded called, or to only use a statefuntion for specific parts you can select to only
call the statefucntion for a set of defined states. 
if the .requestedStates does not exist, or if .requestedStates.all=true, all states will be called,
otherwise, only states with a value true are called, e.g.

settingsStruct.myModule.stateFunction.name='TheNameOfYourModulesStatefunctionFile';
settingsStruct.myModule.use=true;
settingsStruct.myModule.stateFunction.acceptsLocationInput=true;
settingsStruct.myModule.stateFunction.order=0; 
settingsStruct.myModule.stateFunction.requestedStates.experimentPostOpenScreen=true;
settingsStruct.myModule.stateFunction.requestedStates.experimentCleanUp=true;
settingsStruct.myModule.stateFunction.requestedStates.trialSetup=true;
settingsStruct.myModule.stateFunction.requestedStates.trialCleanUpandSave=true;

As you can see this module will only get calles at the beginning and end of an experiment and trial.
This is what is typically used for controlling axternal heardware that you do not collect data from, but
simply start recording and send synchronization and other information

For hardware that collects data, simply also implement and activate the 
settingsStruct.myModule.stateFunction.requestedStates.frameUpdate
state and set the order so that the relevant fields are set before your stimulus needs them.

But you can also use modules to combine multiple generic stimuli in one experiment without having to
create a specific trial stateFunction for that.
Or you could alternate differnt stimilus functions for different trials, simply by setting
the .use field to false/true in the conditions struct of that trial.

%AT END, STATE 3 OPTIONS AS EXPLAINED TO JAKE: Not modular, partially modulay, fully modular, maybe also stimulus not+hardware modular

%% putting it all together
ok, now you will run your first experiment and work your way back from the trialFunction
to the core of pldaps.

    %to start, copy the function loadPLDAPS to a place in your path and edit the 'dirs' to include at least the 
    %path to PLDAPS. Next call loadPLDAPS, so that it is included in your path.

    %now load some settings that should allow to run pldaps in a small screen for now
    > load settingsStruct;
    %next create a pldaps object and specify to use plain.m as the experiment file
    %set the subject to 'test'  and pass the struct we just loaded
    p=pldaps(@plain,'test',settingsStruct)
    %now you have a pldaps object. To start the experiment, call
    p.run
    %shoud should now see a gray screen with a white grid in degrees of visual angle
    %when you move the cursor of the mouse, it will be drawn at a corresponding position in cyan on that screen
    %the screen is full gray for a short time every 5 seconds
    %hit 'd' to step into the debugger. Look around, you are now in the frameUpdate function of if the pldapsDefaultTrialFunction
    %here you can see, that 'q' will quit , 'm' would give a manual reward
    %'p' would end the trial give you a console to change defaultParameters for the next trials. To change paramers that are defined in the conditions, you would have to manually change the cells in p.conditions{} coordingly
    
now lets step back up and understand why we see what we see:
first load a new, fresh version of the object
    p=pldaps(@plain,'test',settingsStruct)

    now type in
    p.trial or
    p.defaultParameters
    this has all settings loaded, and as long as we are not in a trial, p.trial points to p.defaultParameters
    During a trial p.trial will be a struct that holds the merged parameters from p.defaultParameters for that trial
    
    you will see a list of fieldnames
    
    I'll list them here
        
        display     <- all display parameters
        datapixx    <- parameters for datapixx, including options to record analog data (datapixx.adc)
        mouse       <- parameters for the mouse, curently only whether to use it as an eyeposition        
        eyelink     <- all parameters to control eyelink
        pldaps      <- 'internal' parameters, including what drawing pldaps does itself
        session     <- subject and file name, etc        
        sound       <- play sounds?        
        git         <- control whether git should be used to store revisions and changes from the used PLDAPS repository
        newEraSyringePump <- settings to use a syringePump from syringepumps.com for reward
        plexon      <- setting for communicating with plexon systems
        keyboard    <- keybord codes for the keys
        behavior    <- currently only used to define what reward systems to use.
    %ok, now first look at
    p.trial.pldaps.draw, you will noctice that
    p.trial.pldaps.draw.grid.use==true and
    p.trial.pldaps.draw.eyepos.use==true

If you want you can play around with these options and run it again...

now open up the file we provided to setup the experiemnt
    edit plain
    %When it is called by pldaps.run at the beginning of the experiment, only the pldaps object is being passed
    %Thus, first look at the section if nargin==1, that in being excecuted in that case
    %For some things to function correctly we have to call
    
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
    %these are parameters that are also used by the runTrial function to allocate some data.
    %finnally we load a cell of structs into the p.conditions property
    %Before each trial, the properties defined here will be merged with the default properties that werde defined before. 
    %If you want to, set a breakpoint and exlpore the stack of functions

    %ok, now everything is setup,
    %set a breakpoint in plain and start the experiment (p.run)
    %You will notice a few things
    %a) plain gets called even before the first frames with state set to p.trial.pldaps.trialStates.trialSetup or p.trial.pldaps.trialStates.trialPrepare
    %b) within a frame plain gets called multiple times with different states. check out all states:
        %p.trial.pldaps.trialStates
        %note: the Idle states are currently disabled, but could be reactivated if needed
    %c) plain calles 
        %pldapsDefaultTrialFunction(p,state)
        %for each state. This means that all the default behavior will get executed,
        %this includes fetching data from eyelink,datapixx,current mouse position, checking the keyboard (frameUpdate)
        %but also drawing of the grid and eyeposition if the parameters are set to use.
        %If you wanted to leave out this defaultBehavior and do it all by yourself, that is possible,
        %but currently a couple of things defined and allocated by pldapsDefaultTrialFunction are also used by the runTrial
        %function, so we should either clean this up, or you call the pldapsDefaultTrialFunction(p,state) for the required states
    
     %ok, now work with the debugger a bit to get a first idea of what's going on.

%% setting up rig specifig default settings
Now you know the basics of the pldaps system. Let's set it up so it can start easily on your machine to run experiments. 
For this, we will store parameters that are specifig to the rig (e.g. framerate, whether to use eyelink) as a matlab preference.
call
    createRigPrefs
and follow the instructions.
createRigPrefs also opens a gui, to help view and move data in the defaultParameters hierarchy, but you can also change parameters in the command line using
    p.defaultParameters.setLevels([1 2]);
to ensure that you are adding the values at the correct hierarchy level

%% Understanding all parameters
Here all parameters should get explained, along with where they are being used

%% Saving data
Currently, you simply add data during trials to p.trial and change whatever parameters you want to change. After the trial, the struct is compared to the struct that existed at the beginning of the trial and the difference is stored in p.data{iTrial}
This cell array is saved along with the initial parameters, parameters that where changed during the experiment (when you pressed 'p') and the condition cell array.

%% start using pldaps
ok, now you now the basic structure of a pldaps and of the stimuli. All you need is to write your own trial stimulus function