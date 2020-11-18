# PLDAPS 4.4.0

**PL**exon **DA**tapixx **PS**ychtoolbox - Neurophysiology experiment toolbox for MATLAB
---
### New developments with version 4.4.0

**Tracking** [ pds.tracking.trackObj.m, OOP ]

 - _On by default:_    p.trial.tracking.use = true; 
 - Eye/mouse/misc. tracking implemented with OOP object, located in [p.static.tracking]
 - Calibration of raw signals performed on matlab-side allows for independent tracking of multiple sources (e.g. binocular eye) that can be set/recalled for multiple viewing distances. To run calibration, pause experiment, then execute the following from the command window:
     - `pds.tracking.runCalibrationTrial(p)`
 - Calibrations are stored in user-specific & modality-specific calibration files automatically; most recent/appropriate calibration is automatically loaded during experiment startup.
 - _For usage, see new tutorial example:_   **`modularDemo.doRfPos_gabGrid`**


**New tutorial for _'modular PLDAPS'_**

 - Located in `./tutorials/modularDemo`
 - Execute from the command window with  `p = modularDemo.doRfPos_gabGrid()`
 - ...modular experimental design isn't itself new, but full fledged demo code is.
 - More thorough README explanation to come...


**Viewing distance flexibility with new _pdsDisplay object_**
 - OOP-based `p.static.display` object is automatically synced to the standard `p.trial.display`; No manual changes to experiment code are necessary to use
 - OOP allows for automated communication between different experimental elements through event & listener triggers 

---

#### A Wiki is coming!
An effort to develop [at least basic] documentation is being made in [the Wiki](https://github.com/HukLab/PLDAPS/wiki)

---

#### [glDraw] Branch

The glDraw branch is now the default PLDAPS branch, and also the only branch under active development. *Continued use of the `openreception` branch is discouraged.*

As new features are written & tested on the [czuba's] development fork, they will be transferred to stable release status here on the main HukLab PLDAPS project page.

 =======
 

Version 4.3.0 (glDraw commit 354b233) brings additional low-level OpenGL drawing functionality, improved compatibility with various stereo drawing modes, and overall refinements.

##### *Changes to Overlay drawing functionality...*
> The ability to draw elements to the overlay pointer *once*, then have them magically show up on both the overlay/experimenter display *&* the subject display is a cute feature, but it's time is coming to an end. Going forward, expect that **things rendered to the Overlay pointer will only appear on the overlay window**. Dealing with the ambiguity of 'which eye should the overlay render to during stereomodes?' is a major reason for this change. I can see of no current solution that doesn't require tedious piles of checks & drawBuffer changes that wouldn't outweigh their utility. In most all cases, the things being rendered this way are not so computationally intensive that there is a large benefit to only rendering them once in code, and the inherent limitations of indexd drawing (no alpha blending or smooth motion) make it unsuitable for many experimental stimulus applications anyway.

> This may break/change functionality of some code (e.g. eyelink calibration targets), but fixes are being implemented as they come up. If you do come across an unfixed instance, feel free to contribute a solution.  --czuba, 2018-05-11

---

**Spring 2020 Note:**

* minimal updates have been made to the text below to ensure the first few steps are at least *'not wrong'*. Improved documentation is being made in the repo Wiki (...also slowly making its way over from the development branch)
 
...for now, on with the [outdated] readme!

---

## Before we start
- PLDAPS is primarily developed/tested/supported on OSX (ver ~~10.10~~ 10.15) and Ubuntu (ver >= 16.04)
- Most modern Matlab versions should suffice; ~~>=2016b~~ 2019a is recommended
- Psychtoolbox needs to be installed
- If you are planning to use Datapixx, you should download a current version of the datapixx toolbox from vpixx.com *and place it in the matlab path above[shadowing] the PTB copy*. The datapixx code provided with PTB should be thought of as only a placeholder and is totally outdated.
- For a recording rig, all basic testing should be done (e.g. VBLSyncTest with and without datapixx, etc)

## Getting started / installation

Create a local copy of PLDAPS by cloning the git repository ~~and select the version 4.2 branch (openreception)~~.
In a terminal window, first go to the directory in which you want the PLDAPS directory to reside in.

```
    git clone https://github.com/HukLab/PLDAPS.git ~/MLtoolbox/PLDAPS
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



> __Quick aside on handle classes__
> We use a handle class for pldaps because it allows a reduction of some memory allocation, which translates to increased speed during the trial. There are a couple of downsides to using handle classes (for one, it appears that storing function handles in a handle class reduces the performance.), but this appears to be the fastest easy way to be able to add data to a struct from inside a subfunction. It might be possible to go via a mex file to get real pointer behavior without the downsides of a handle class

> Specifically, assume you have an object p of type pldaps

> ```Matlab
>     p=pldaps;
> ```

> Any changes made to a copy of `p`, will also effect `p`, as they are in fact using the same memory.

> ```Matlab
>     p2=p;
>     p2.defaultParameters.newParameter='I told you so';
>     display(p.defaultParameters.newParameter);
> ```
> notice that I created a new Parameter newParameter in object `p2`, but 
> but now you can also access it using `p`, because `p2` und `p` are identical.


## Creating a `pldaps` class:
Typical use of the pldaps contructor includes the following inputs*:
    1. Experiment setup function
    2. Subject identifier
    3. Settings struct containing hierarchies for additional experiment components (e.g. ) and/or changes to defaultParameters (e.g. to add/change values from your 'rigPrefs' to be applied only on this particular run)

The order of inputs is somewhat flexible**, but the only officially supported order is as follows:
```Matlab
	p = pldaps( @fxnsetupFunction, 'subject', settingsStruct )
```

- __setupFunction__ must be a function handle (i.e. @fxn ) to your setup function
	- ...using a function handle here allows tab completion, which is nice
- __subject__ must be a string input.
- __settingsStruct__ must be a structure. 
	- Defining core modules/components of your experiment (i.e. hardware elements, stimulus parameters, etc...see demo code for examples)
	- Fieldnames matching fields already present in defaultParameters  [& within their respective param struct hierarchies] will take on the value in settingsStruct.
		- e.g. toggle the overlay state for this run by creating `settingsStruct.display.useOverlay = 1`. Note: you need not build every field of the .display struct into this; fieldnames will be matched/updated piecewise

- _condsCell_, a fourth input of a cell struct of parameters for each trial can also be accepted. Use of this input is relatively depreciated and should only really be used for debugging purposes. Trial specific parameters are better dealt with inside your setupFunction (when setting up p.conditions{}).

> (__*__ all inputs are _technically_ optional, but PLDAPS won't do much without them.)
> (__**__ In most—but not all—cases PLDAPS will still be able to parse disordered inputs, but lets not leave things to chance when we don't have to.)

## Running pldaps 

`p` now exists as a PLDAPS class in the workspace, but the experiment hasn't started yet, and the provided experiment function has not been called yet.

Execute the .run method to actually begin the experiment:
```Matlab
p.run
```

### pldaps.run
__`pldaps.run`__  will open the PTB screen and interface with a number of external hardware devices and will call a function each trial.

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
