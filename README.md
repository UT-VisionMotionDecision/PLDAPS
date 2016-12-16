PLDAPS 4.2
==========

**PL**exon **DA**tapixx **PS**ychtoolbox - Neurophysiology experiment toolbox for MATLAB

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

## Before we start
- PLDAPS has only been tested on Matlab 2014b and 2015b on OSX 10.10 and on  Matlab 2015b and 2016a on Ubuntu 16.04
- Psychtoolbox needs to be installed
- If you are planning to use Datapixx, you should download a current version of the datapixx toolbox from vpixx.com and place it in the matlab path above PTB. The toolbox provided with PTB tends to be outdated.
- For a recording rig, all basic testing should be done (e.g. VBLSyncTest with and without datapixx, etc)

## Getting started / installation

Create a local copy of PLDAPS by cloning the git repository and select the version 4.2 branch (openreception).
In a terminal window, first go to the directory in which you want the PLDAPS directory to reside in.

```
    git clone https://github.com/HukLab/PLDAPS.git
    git checkout openreception
```

Now start Matlab and copy the function `loadPLDAPS_template.m` to a place in your path (e.g. your Matlab start folder), rename it to `loadPLDAPS.m` and edit the 'dirs' to include at least the path you just installed PLDAPS in. 
Now whenever you want to include PLDAPS in your path, just call
    `loadPLDAPS`

## Framework:
### pldaps
The core is a class called `pldaps`.

When a `pldaps` is created, it will load default parameters from different sources 
into a field called `defaultParameters`. This is again a class (named `@params`) 
that can handle a hierarchy of parameters.
Importantly, pldaps is a handle class.

###Quick aside on handle classes
We use a handle class for pldaps because it allows a reduction of some memory allocation, which translates to increased speed during the trial. There are a couple of downsides to using handle classes (for one, it appears that storing function handles in a handle class reduces the performance.), but this appears to be the fastest easy way to be able to add data to a struct from inside a subfunction. It might be possible to go via a mex file to get real pointer behavior without the downsides of a handle class

Specifically, assume you have an object p of type pldaps

```Matlab
    p=pldaps;
```

Any changes made to a copy of `p`, will also effect `p`, as they are in fact using the same memory.

```Matlab
    p2=p;
    p2.defaultParameters.newParameter='I told you so';
    display(p.defaultParameters.newParameter);
```
notice that I created a new Parameter newParameter in object `p2`, but 
but now you can also access it using `p`, because `p2` und `p` are identical.


###creating a `pldaps` class:
The pldaps contructor accepts the following inputs, all are optional:
    1. a subject identifier (string)
    2. a function name or handle that sets up all experiement parameters
    3. a struct with changes to the defaultParameters, this is usefull for debugging, but could also be used to replace the function.
    4. a cell array containing a struct with parameters for each trial (this is typically set later in the fucntion you set in 2.)

As long as the inputs are classifiable, the order is not important, otherwise 
for the remaining unclassified inputs the above order is assumed.

Specifically when both subject and the function are strings the input must be

```Matlab
    p=pldaps('subject','functionName', parameterStruct);
```

or

```Matlab
    p=pldaps('subject', parameterStruct, 'functionName');
```

or

```Matlab
    p=pldaps(parameterStruct,'subject', 'functionName');
```

but not

```Matlab
    p=pldaps('functionName','subject', parameterStruct);
```

but when using a handle, this is ok:

```Matlab
    p=pldaps(@functionName,'subject', parameterStruct);
```

using a handle also enables tab completion for the function name, so I'd recomment using a handle

now the `defaultParameters` are loaded, but the experiment hasn't started yet, and the provided experiment function has not been called yet.

## Running pldaps 
###pldaps.run
`pldaps.run` runs the experiment. This will open the PTB screen and interface with a number of external hardware devices and will call a function each trial.

Of course there is no need to use this, if you wanted to run your own experiment script and only wanted to use pldaps for its screen opening and device management, but in that case there might not be any benefit of using this version of pldaps.

`pldaps.run` opens a Psychtoolbox window using `p.openScreen`

once the Psychtoolbox screen is created
`pldaps.run` will call the experiment function provided in the constructor call (`@functionname` described above).
This function 
- can define the functions being called each trial (later), 
- define any further colors you want to use in a datapixx dual clut scenario
- create anything that should be created before the first trial starts, 
- define any stimulus parameters that are true for all trials in `p.defaultParameters`
- and should add a cell of structs to p.conditions that that holds the changes in parameters from therse defaults for _each_trial_

note: in later versions, `p.conditions` might actually only hold information about certain conditions and another field the info of what conditions to use in each trial.

note: since the screen is already created, basic screen parameters like the backgound color must be defined before the p.run is called.

### pldaps.runTrial
unless another function is specified in the parameters as the 
`p.defaultParameters.pldaps.trialMasterFunction`
it defaults to `dv.defaultParameters.pldaps.trialMasterFunction="runTrial"`;

This is a generic trial function that takes care of the correct course of a trial.
It will run through different stages for the trial and in a loop for each frame run through stages from frameUpdate to frameFlip.

For each stage, instead of doing something itself, it calles another function, defined in
`p.defaultParameters.pldaps.trialFunction` that take the pldaps class and a numerical state number as input.

**Important:** The function specified in `p.defaultParameters.pldaps.trialFunction` is what manages the flow of each trial. This is the only function that needs to be implemented by the user to take care of the drawing of the stimulus.

note: version 4.0 had a trialMasterFunction that instead took a class as a stimulus Function and had to have methods names frameUpdate to frameFlip. This is a cleaner, but might be more difficult for a matlab novice to understand. This is the reason for the change to the state function.

### pldapsDefaultTrialFunction
all basic features of pldaps from flipping the buffers to drawing the eye position of the experimentor screen are
implemented in a function called `pldapsDefaultTrialFunction`
To make use of these, this function must simply be called by your trialFunction.

## putting it all together
ok, now you will run your first experiment and work your way back from the trialFunction
to the core of pldaps.


to start, copy the function `loadPLDAPS` to a place in your path and edit the 'dirs' to include at least the 
path to PLDAPS. Next call loadPLDAPS, so that it is included in your path.

```Matlab
loadPLDAPS
```

now load some settings that should allow to run pldaps in a small screen for now

```Matlab
> load settingsStruct;
```

next creat a pldaps object and specify to use plain.m as the experiment file
set the subject to 'test'  and pass the struct we just loaded

```Matlab
p=pldaps(@plain,'test',settingsStruct)
```

now you have a pldaps object. To start the experiment, call
```Matlab
p.run
```
After the PTB window opens, you should now see a gray screen with a white grid in degrees of visual angle. When you move the cursor of the mouse, it will be drawn at a corresponding position in cyan on that screen. The screen is full gray for a short time every 5 seconds. Hit 'd' on the keyboard to step into the debugger. Look around, you are now in the `frameUpdate` function of if the `pldapsDefaultTrialFunction` where you can see, that 'q' will quit , 'm' would give a manual reward 'p' would end the trial give you a console to change defaultParameters for the next trials. To change paramers that are defined in the conditions, you would have to manually change the cells in `p.conditions{}` accoordingly.

now lets step back up and understand why we see what we see:
first load a new, fresh version of the object

```Matlab
    p=pldaps(@plain,'test',settingsStruct)
```    

now type in 

```
p.trial
```

or

```
p.defaultParameters
```

this has all settings loaded, and as long as we are not in a trial, 
`p.trial` points to `p.defaultParameters`
   
During a trial, `p.trial` will be a struct that holds the merged parameters from `p.defaultParameters` for that trial
    
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
    
ok, now first look at `p.trial.pldaps.draw`, you will noctice that
    `p.trial.pldaps.draw.grid.use==true` and
    `p.trial.pldaps.draw.eyepos.use==true`
    
If you want you can play around with these options and run it again...

Now open up the file we provided to setup the experiemnt
edit plain.
When it is called by `pldaps.run` at the beginning of the experiment, only the `pldaps` object is being passed.
Thus, first look at the section `if nargin==1`, that in being excecuted in that case
For some things to function correctly we have to call
    
`pdsDefaultTrialStructure(p)` and  `defaultTrialVariables(p)`
This is something that still needs cleaning up, but it won't harm having it here.

Next the function that should be called for all the drawing and calculations of your stimulus is defined by

`p.defaultParameters.pldaps.trialFunction='plain';`   
    
I.e. in this example case, we use the same function to setup the experiment parameters and to calculate the stimulus. This is typically not the case later, when you have one stimulus file and several experiments that you define that use the sae stimulus code.

If you do not want to use the default trial function that is called for each Trial and manages the frames, etc, you can also define a
`dv.defaultParameters.pldaps.trialMasterFunction='runTrial';` but we won't do that here.

next we define `p.trial.pldaps.maxTrialLength` and  `p.trial.pldaps.maxFrames`
    
These are parameters that are also used by the `runTrial` function to allocate some data.

Finally we load a cell of structs into the `p.conditions` property.

Before each trial, the properties defined here will be merged with the default properties that werde defined before. 
If you want to, set a breakpoint and explore the stack of functions

ok, now everything is setup,
set a breakpoint in plain and start the experiment (`p.run`)
You will notice a few things:

1. `plain` gets called even before the first frames with state set to `dv.trial.pldaps.trialStates.trialSetup` or `dv.trial.pldaps.trialStates.trialPrepare`
2. within a frame `plain` gets called multiple times with different states. check out all states:

```
dv.trial.pldaps.trialStates
```
    
    note: the Idle states are currently disabled, but could be reactivated if needed
3. plain calls 
    `pldapsDefaultTrialFunction(p,state)`
    
    for each state. This means that all the default behavior will get executed, this includes fetching data from eyelink,datapixx,current mouse position, checking the keyboard (frameUpdate), but also drawing of the grid and eyeposition if the parameters are set to use.
    If you wanted to leave out this default behavior and do it all by yourself, that is possible, but currently a couple of things defined and allocated by `pldapsDefaultTrialFunction` are also used by the `runTrial` function, so we should either clean this up, or you call the `pldapsDefaultTrialFunction(p,state)` for the required states

ok, now work with the debugger a bit to get a first idea of what's going on.

## setting up rig specifig default settings
Now you know the basics of the pldaps system. Let's set it up so it can start easily on your machine to run experiments. 
For this, we will store parameters that are specifig to the rig (e.g. framerate, whether to use eyelink) as a matlab preference.
call `createRigPrefs` and follow the instructions.

`createRigPrefs` also opens a gui, to help view and move data in the defaultParameters hierarchy, but you can also change this in the command line using
    
    `p.defaultParameters.setLevels([1 2]);`

to ensure that you are adding the values at the correct hierarchy level


### Understanding all parameters
Here all parameters should get explained, along with where they are being used

## Saving data
Currently, you simply add data during trials to p.trial and change whatever parameters you want to change. After the trial, the struct is compared to the struct that existed at the beginning of the trial and the difference is stored in `p.data{iTrial}`
This cell array is saved along with the initial parameters, parameters that where changed during the experiment (when you pressed 'p') and the condition cell array.

## start using pldaps
ok, now you now the basic structure of a pldaps and of the stimuli. All you need is to write your own trial stimulus function