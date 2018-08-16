function X = ShuffleMex(Arg1, Arg2, Arg3)  %#ok<INUSD,STOUT>
% Random permutation of array elements
% SHUFFLE works in Inplace, Index and Derange mode:
%
% 1. INPLACE MODE: Y = ShuffleMex(X, Dim)   - - - - - - - - - - - - - - - - - - - -
% The elements of the input array are randomly re-ordered along the specified
% dimension. In opposite to X(RANDPERM(LENGTH(X)) no temporary memory is used,
% such that SHUFFLE is much more efficient for large arrays.
% INPUT:
%   X: Array of any size. Types: DOUBLE, SINGLE, CHAR, LOGICAL,
%      (U)INT64/32/16/8. The processed dimension must be shorter than 2^32
%      elements. To shuffle larger or complex arrays, use the Index mode.
%   Dim: Dimension to operate on.
%      Optional, default: [], operate on first non-singleton dimension.
% OUTPUT:
%   Y: Array of same size and type as X, but with shuffled elements.
%
% 2. INDEX MODE: Index = ShuffleMex(N, 'index', NOut)   - - - - - - - - - - - - - -
% A vector of shuffled indices is created as by RANDPERM, but faster and using
% the smallest possible integer type to save memory. The number of output
% elements can be limited. This method works for cells, structs or complex
% arrays.
% INPUT:
%   N:      Numeric scalar >= 0.
%   String: 'index'.
%   NOut:   Optional, number of outputs, NOut <= N. Default: N.
% OUTPUT:
%   Index:  [1 x nOut] vector containing the shuffled elements of the vector
%           [1:N] vector. To limit the memory usage the smallest possible type
%           is used: UINT8/16/32 or INT64.
%
% 3. DERANGEMENT MODE: Index = ShuffleMex(N, 'derange', NOut)   - - - - - - - - - -
% Equivalent to Index mode, but all elements Index[i] ~= i.
%
% CONTROL COMMANDS:  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ShuffleMex(S, 'seed'): S is either empty, scalar or a [1 x 4] DOUBLE vector to
%      set the random number  generator to a certain state. 4 integers between 0
%      and 2^32-1 are recommended for maximum entropy. If S is empty the default
%      seed is used.
% ShuffleMex([], 'lock'): Lock Mex in the memory such that "clear all" does not
%      reset the random  number generator. If the Mex was compiled with
%      -DAUTOLOCK it is locked automatically.
% ShuffleMex([], 'unlock'): Unlock the Mex file to allow a recompilation.
% ShuffleMex(): Display compiler settings and status: Fast/exact integer, accept
%      cell/struct, current lock status, auto-lock mode.
%
% EXAMPLES:
%   ShuffleMex(12345678901, 'seed');
%   R = ShuffleMex(1:8)             %  [5, 8, 7, 4, 2, 6, 3, 1]
%   R = ShuffleMex('abcdefg')       %  'gdfbcea'
%   R = ShuffleMex([1:4; 5:8], 2)   %  [3, 4, 2, 1;  8, 6, 7, 5]
%   I = ShuffleMex(8, 'index');     %  UINT8([3, 6, 5, 2, 4, 7, 8, 1])
% Choose 10 different rows from a 1000 x 100 matrix:
%   X = rand(1000, 100);       Y = X(ShuffleMex(1000, 'index', 10), :);
% Operate on cells or complex arrays:
%   C = {9, 's', 1:5};         SC = C(ShuffleMex(numel(C), 'index'));
%   M = rand(3) + i * rand(3); SM = M(:, ShuffleMex(size(C, 2), 'index'))
%
% NOTES: ShuffleMex(X) is about 50% to 85% faster than: Y = X(randperm(numel(X)).
%   It uses the Knuth-shuffle algorithm, also known as Fisher-Yates-shuffle.
%   The random numbers are created by the cute KISS algorithm of George
%   Marsaglia, which has a period of about 2^124 (~10^37).
%   More notes in ShuffleMex.c.
%
% COMPILATION: See ShuffleMex.c
%
% Tested: Matlab 6.5, 7.7, 7.8, WinXP, 32bit
%         Compiler: LCC2.4/3.8, BCC5.5, OWC1.8, MSVC2008
% Assumed Compatibility: higher Matlab versions, Mac, Linux, 64bit
% Author: Jan Simon, Heidelberg, (C) 2010-2011 j@n-simon.de
%
% See also RAND, RANDPERM.
% FEX:

% $JRev: R-m V:012 Sum:Q65/zXZqnvFX Date:07-Mar-2011 00:49:06 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $UnitTest: uTest_ShuffleMex $
% $File: Tools\GLSets\ShuffleMex.m $

% History see ShuffleMex.c

% Some Matlab algorithms for the Knuth-ShuffleMex: --------------------------------
% They are faster than Matlab's RANDPERM methods, but the MEX is recommended!

% n = numel(X);
% for i = 2:n      % Knuth shuffle in forward direction:
%    w    = ceil(rand * i);   % 1 <= w <= i
%    t    = X(w);
%    X(w) = X(i);
%    X(i) = t;
% end
 
% for i = n:-1:2   % Knuth shuffle in backward direction:
%    w    = ceil(rand * i);   % 1 <= w <= i
%    t    = X(w);
%    X(w) = X(i);
%    X(i) = t;
% end

% for i = 1:nOut   % Limit output:
%    w    = ceil(rand * (n - i + 1)) + (i - 1);   % i <= w <= n
%    t    = X(w);
%    X(w) = X(i);
%    X(i) = t;
% end
% X = X(1:nOut);

error(['JSimon:', mfilename, ':NoMex'], 'Need compiled mex file!');
