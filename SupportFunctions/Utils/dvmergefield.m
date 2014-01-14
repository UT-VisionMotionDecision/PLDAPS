function [dv] = dvmergefield(dv,defaults,nowarning)
    fn = fieldnames(defaults);
    for ii = 1:length(fn)
        if ~isfield(dv,fn{ii}) || isempty(dv.(fn{ii}))
            dv.(fn{ii}) = defaults.(fn{ii});
        end
    end
    
    if nargin < 3 || nowarning == 0
        fn = fieldnames(dv);
        for ii = 1:length(fn)
            if ~isfield(defaults,fn{ii});
                warning('setdefaults:unknownarg','Argument %s is unsupported',fn{ii});
            end
        end
    end
end