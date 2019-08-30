function base = applyDefaults(base, def)
% function pModule = applyDefaults(base, def)
% 
% Checks [base] input struct to ensure that all fields in [def]ault input struct
% are present. Any absent fields will be added to base with corresponding values
% from def.
%   (NOTE: recursive on any def fields that are also structs)
% 
% [base] input is presumed to be a PLDAPS module, therefore .stateFunction and
% .use fields are ignored. This was primarily written for setting up all other
% parameters needed for a given module.
% 
% % ------
% %% EXAMPLE USAGE when the output is a PLDAPS module:
%   sn = 'fix'; % module name (i.e. p.trial.(sn) )
%   
%	% list of default parameters
%	def = struct(...
%       'on', true,...
%       'mode', 2,...   % limit type (0==pass/none, 1==square, 2==euclidean/circle)
%       'fixPos',[0 0],... % xy position
%       'rmax',3,...    % outer radius in visual degrees
%       'reps',4);      % number of distinct fixation textures
% 
%   p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
% % ------
% 
% 2017-11-08  TBC  Wrote it. <czuba@utexas.edu>
% 

% Parse inputs
if nargin <2 || isempty(def)
    def = struct(); 
end


% funky subfunction to deal with case of recursion inside a package
fxn = getFxnHandle(mfilename('fullpath'));

% detect existing module parameters
baseFields = fieldnames(base);
% ignore core module fields (.use & .stateFunction)
baseFields(strcmp(baseFields, 'stateFunction')) = [];
baseFields(strcmp(baseFields, 'use')) = [];

% check for substructs in def
defFields = fieldnames(def);
defsubstruct = structfun(@isstruct, def);

% find any missing fields
[~, ismissing]= setdiff(defFields, baseFields);

% trim defFields list
defFields = defFields( union(ismissing, find(defsubstruct)) );

% apply to base
if ~isempty(defFields)
    for i = 1:numel(defFields)
        if ~isstruct(def.(defFields{i}))
            % easy...
            base.(defFields{i}) = def.(defFields{i});
        else
            % recursive on substructs
            if ~isfield(base,defFields{i}), base.(defFields{i}) = struct;
            elseif ~isstruct(base.(defFields{i})); error('Attempting to merge incompatible default fields.'); end
            % do it
            base.(defFields{i}) = feval(fxn, base.(defFields{i}), def.(defFields{i}));
        end
    end
end

end % end applyDefaults


% % % % % % % % % %
% % Sub-functions
% % % % % % % % % %

%% getFxnHandle
function fxn = getFxnHandle(inStr)
    % inStr is full path to matlab function
    % --if path contains a package,
    %   make function handle specific to package
    % 

    isPkg = strfind(inStr, '+');

    if ~isempty(isPkg)
        inStr = inStr((isPkg(1)+1):end);
        seps = strfind(inStr, filesep);
        inStr(seps) = '.';
    else
        [~, inStr] = fileparts(inStr);
    end

    fxn = str2func(inStr);

end % end getFxnHandle



