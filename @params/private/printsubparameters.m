function printsubparameters(p, fieldname, maxDepth)

if nargin <3
    maxDepth=1;
end

%%
idx=strcmp({p.flatStruct.identifier},fieldname);
maxDepth=maxDepth+length(p.flatStruct(idx).parentLevels);


parts_inds=(strncmp({p.flatStruct.identifier},fieldname,length(fieldname)));
a=p.flatStruct(parts_inds);
nDepth=cellfun(@length, {a.parentLevels});
a=a(nDepth<=maxDepth);

ids={a.identifier};

id=cellfun(@(x) lower([{''} x]), {a.parentLevels}, 'UniformOutput', false); 
leafs=cellfun(@(x) [sprintf(['.' '%s'],x{1:end-1}) repmat('.',1,length(x)) x{end}], id, 'UniformOutput', false); 
nodes=cellfun(@(x) [sprintf(['.' '%s'],x{1:end-1}) '.' x{end} '.'], id, 'UniformOutput', false); 

id=leafs;
id([a.isNode])=nodes([a.isNode]);

[~, idx]=sort(id);

ids=ids(idx);

isNode=[a(idx).isNode];
helptext={a(idx).help};

%%
prevLeaf=false;
for iID=2:length(ids)
    tabName=['' strrep(ids{iID}, '.', '. ')];
    if ~isempty(helptext{iID})
        shorthelp=strsplit(helptext{iID},'\\n');
        if length(shorthelp)>1
            shorthelp=[shorthelp{1} ' ...'];
        else
            shorthelp=shorthelp{1};
        end
    else
        shorthelp = '';
    end
    if isNode(iID)
        if prevLeaf
            fprintf('\n');
            prevLeaf=false;
        end
        fprintf('\t<a href="matlab: help(%s,''%s'')">%s.</a>\t%s\n','p.defaultParameters',ids{iID},tabName,shorthelp);
    else
        prevLeaf=true;
        fprintf('\t<a href="matlab: help(%s,''%s'')">%s</a>\t%s\n','p.defaultParameters',ids{iID},tabName,shorthelp);
    end 
end

