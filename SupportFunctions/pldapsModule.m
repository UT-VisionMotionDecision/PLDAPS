function output = pldapsModule(varargin)
% function output = pldapsModule(varargin)
% Helper function for initializing use of a PLDAPS module. Accepts the following parameter name-value pairs.
% Only for setup of core module structure expected by modular PLDAPS (current ver: 4.2, "openreception"),
% any additional parameters needed by module should be manually added after creation (see example).
% 
% This function will help ensure the core module struct is properly formatted (with current, *and future*
% standards/features). Current s.o.p. (Fall 2017) is to create these module structures as part
% of the settingsStruct that will be passed as input during creation of a pldaps() object.
% 
% All inputs are optional (a basic empty module structure will be returned)...though a module cannot function
% without a viable function [name] to execute. See descriptions for defaluts. Order of input pairs is
% not important, but following some reasonable convention will make your code more readable in the future.
% 
% Acceptable inputs:
%   [use]       Set this module as active   (...default is almost always sufficient here)
%               --logicial, default: true
%   [name]      Function name (string) that should be called when executed
%               -- i.e. what will be used by runModularTrial.m for:  feval( <name> )
%               -- string, default: ''
%   [modName]   Fieldname (string) associated with this module in your pldaps structure
%               -- i.e.  p.trial.(modName)
%               -- string, default: []
%   [order]     Value corresponding to order this module should be evaluated relative to other modules
%               -- PLDAPS will execute each module based on the sort of all active module 'order' values, -inf:0:inf
%               -- ...ex: when using defaultTrialFunction as a module, an early order value will ensure relevant
%                  eye/keyboard/spike responses are up-to-date when subsequent modules are evaluated
%               -- default: inf
%   [requestedStates]
%               Cell of trial states (strings) in which this module should be called. (see example below)
%               -- output formatted as a struct with logical true values for each requested trial state.
%               -- defaut: 'all' ==> active for all states called    (***no need to enumerate each state when set to 'all')
%   [useAsFilename]         {{ Not yet implemented, but soon... TBC 2017-11-06 }} 
%               Flag to use this module's "modName" string when generating the saved filename for this PLDAPS session
%               -- helpful for differentiating distinct file/session types that may share a common pldaps setup function
%               -- default: false
%   
% 
% %% EXAMPLE USAGE:
%   % Create a module from the default trial function, and make sure it is executed early on in the order of modules.
%   n = 'pdTrialFxn'; % modName
%   settignsStruct.(n) = pldapsModule('modName',n, 'name','pldapsDefaultTrialFunction', 'order',-100);
% 
%   % A fixation module, only active for certain states
%   n = 'fix'; % modName
%   settingsStruct.(n) = pldapsModule('modName',n, 'name','myModules.basicFixation',...
%                           'requestedStates',{'frameDraw','trialItiDraw','experimentPostOpenScreen'},...
%                           'order',0);
%   % Parameters specific to a particular module can then be added as fields under that modName, e.g.
%   settingsStruct.(n).fixPos = [0 0];
%   settingsStruct.(n).type = 1;
%   
% 
% 2017-11-06  TBC  Wrote it. <czuba@utexas.edu>
%                  NOTE: modules *can* have same order value, but the order in which they are executed will not
%                  be known. ...in future, may try implementing parfor execution of modules with same (or ==0)
%                  order value.
% 


% Create input parser
pp = inputParser;
pp.addParameter('use', true, @islogical);
pp.addParameter('name', ''); % ...misnomer; this is the function name string for feval() use when the module is used
pp.addParameter('order', inf, @isnumeric);
pp.addParameter('modName', []); % alternate to the long .acceptsLocationInput flag
pp.addParameter('matrixModule', false); % allow condition index to be assigned on a per-module basis
pp.addParameter('requestedStates', 'all');
pp.addParameter('useAsFilename', false, @islogical); % to be implemented... TBC 2017-11-06
% % % % legacy fields (no longer needed!)
% % % pp.addParameter('acceptsLocationInput', true, @islogical);

% Do the parsing
try
    pp.parse(varargin{:});
catch
    warning('Inputs for pldapsModule.m could not be parsed')
    keyboard
end
argin = pp.Results;

% Pull out the "use" property
output.use = argin.use;
argin = rmfield(argin,'use');

% All other core parameters get piled into the module field .stateFunction  (...by prior convention)
vals = struct2cell(argin);
fn = fieldnames(argin);
output.stateFunction = struct;
for i = 1:numel(vals)
    output.stateFunction.(fn{i}) = vals{i};
end

% convert .requestedStates to necessary format
if iscell(output.stateFunction.requestedStates)
    reqStates = output.stateFunction.requestedStates;
    output.stateFunction.requestedStates = struct;
    for i = 1:numel(reqStates)
        output.stateFunction.requestedStates.(reqStates{i}) = true;
    end
end

end % end function
