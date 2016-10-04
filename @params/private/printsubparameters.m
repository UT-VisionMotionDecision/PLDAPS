function printsubparameters(p, fieldname, maxDepth)

if nargin <3
    maxDepth=1;
end

%%
idx=strcmp({p.helpStruct.identifier},fieldname);
parentLevels={p.helpStruct.parentLevels};
maxDepth=maxDepth+length(parentLevels{idx});

parts_inds=(strncmp({p.helpStruct.identifier},fieldname,length(fieldname)));
a=p.helpStruct(parts_inds);
isNode=[p.helpStruct(parts_inds).isNode];
nDepth=cellfun(@length, parentLevels(parts_inds));
parentLevels=parentLevels(parts_inds);


a=a(nDepth<=maxDepth);
isNode=isNode(nDepth<=maxDepth);
parentLevels=parentLevels(nDepth<=maxDepth);
ids={a.identifier};

id=cellfun(@(x) lower([{''} x]), parentLevels, 'UniformOutput', false); 
leafs=cellfun(@(x) [sprintf(['.' '%s'],x{1:end-1}) repmat('.',1,length(x)) x{end}], id, 'UniformOutput', false); 
nodes=cellfun(@(x) [sprintf(['.' '%s'],x{1:end-1}) '.' x{end} '.'], id, 'UniformOutput', false); 

id=leafs;
id(isNode)=nodes(isNode);

[~, idx]=sort(id);

ids=ids(idx);

isNode=isNode(idx);
helptext={a(idx).help};

fids={p.flatStruct.identifier};
%%
prevLeaf=false;
for iID=2:length(ids)
    if ismember(ids{iID},fids)
       def=true;
    else
        def=false;
    end
    tabName=['' strrep(ids{iID}, '.', '. ')];
    if ~isempty(helptext{iID})
        shorthelp = helptext{iID};
        shorthelp_idx = strfind(helptext{iID},'\n');
        if ~isempty(shorthelp_idx)%length(shorthelp)>1
            shorthelp=[shorthelp(1:shorthelp_idx-1) ' ...'];
%         else
%             shorthelp=shorthelp{1};
        end
    else
        shorthelp = '';
    end
    if isNode(iID)
        if prevLeaf
            fprintf('\n');
            prevLeaf=false;
        end
        if def
            fprintf('\t<a href="matlab: help(%s,''%s'')">%s.</a>\t%s\n','p.defaultParameters',ids{iID},tabName,shorthelp);
        else
            fprintf(2,'\t<a href="matlab: help(%s,''%s'')">%s.</a>\t%s\n','p.defaultParameters',ids{iID},tabName,shorthelp);
        end
    else
        prevLeaf=true;
        if def
            fprintf('\t<a href="matlab: help(%s,''%s'')">%s</a>\t%s\n','p.defaultParameters',ids{iID},tabName,shorthelp);
        else
            fprintf(2,'\t<a href="matlab: help(%s,''%s'')">%s</a>\t%s\n','p.defaultParameters',ids{iID},tabName,shorthelp);
        end
    end 
end

