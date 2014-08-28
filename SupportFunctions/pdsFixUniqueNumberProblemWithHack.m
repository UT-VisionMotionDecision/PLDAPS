function PDS = pdsFixUniqueNumberProblemWithHack(PDS, strobed)
% PDS = pdsFixUniqueNumberProblemWithHack(PDS, strobed)
% SUPER hack... DO NOT Trust this
dpstarts = PDS.timing.datapixxStartTime(:)-PDS.timing.datapixxStartTime(1);
plstarts = strobed.times(:)-strobed.times(1);

A = bsxfun(@minus, dpstarts, plstarts');
[~, col] = min(A.^2);
if numel(unique(col))==numel(col)
    PDS.unique_number_new = strobed.values(col,:);
end
    