classdef pdsdv < handle
 properties
    pass
    movav
    useDatapixxbool
    useEyelink
    useMouse
    quit
    j
    trial
    kb
    dp
    disp
    useSpikeServer
    subj
    pref
    trialFunction
    goodtrial
    finish
    pa
    st
    event
    states
    sound
    custom_calibration
    el 
 end
 
 methods
        function obj = pdsdv(inStruct)
            if nargin>0
                fn=fieldnames(inStruct);
                for k=1:length(fn)
    %                 if(strcmp(fn{k},'disp'))
    %                     obj.('displ')=inStruct.(fn{k});                  
    %                 else
                    if(strcmp(fn{k},'events'))
                        obj.('event')=inStruct.(fn{k});
                    else
                        obj.(fn{k})=inStruct.(fn{k});
                    end
                end
            end
        end
        
        function out = toStruct(obj)
            fn=properties(obj);
            for k=1:length(fn)
%                 if(strcmp(fn{k},'displ'))
%                     out.('disp')=obj.(fn{k});
%                 else
                if(strcmp(fn{k},'event'))
                    out.('events')=obj.(fn{k});
                else
                    out.(fn{k})=obj.(fn{k});
                end
            end
        end
 end
   
    
%  try 2
% classdef pdsdv < dynamicprops
%     methods
%         function obj = pdsdv(inStruct)
%             fn=fieldnames(inStruct);
%             for j=1:length(fn)
%                 if(strcmp(fn{j},'disp'))
%                     obj.addprop('displ');
%                     obj.('displ')=inStruct.(fn{j});
%                 elseif(strcmp(fn{j},'events'))
%                     obj.addprop('event');
%                     obj.('event')=inStruct.(fn{j});
%                 else
%                     obj.addprop(fn{j});
%                     obj.(fn{j})=inStruct.(fn{j});
%                 end
%             end
%         end
%         
%         function out = toStruct(obj)
%             fn=properties(obj);
%             for j=1:length(fn)
%                 if(strcmp(fn{j},'displ'))
%                     out.('disp')=obj.(fn{j});
%                 elseif(strcmp(fn{j},'event'))
%                     out.('events')=obj.(fn{j});
%                 else
%                     out.(fn{j})=obj.(fn{j});
%                 end
%             end
%         end
%      end
     
%try 1     
%     properties 
%         data
%     end
%     
%     methods
%         function obj = pdsdv(inStruct)
%             obj.data = inStruct;
%         end
%         
%         function out = subsref(obj,varargin)
%             out = subsref(obj.data, varargin{:});
%         end
%         
%          function obj = subsasgn(obj,varargin)
%             obj.data = subsasgn(obj.data, varargin{:});
%          end
%         
%          function names = fieldnames(obj)
%              names = fieldnames(obj.data);
%          end
%          
%          function out = isfield(obj,varargin)
%              out = isfield(obj.data, varargin{:});
%          end
%          
%          function out = toStruct(obj)
%              out = obj.data;
%          end
%          
%     end
end