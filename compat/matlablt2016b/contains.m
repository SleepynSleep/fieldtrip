function [varargout] = contains(varargin)

% CONTAINS True if text contains a pattern.
%   TF = contains(S,PATTERN) returns true if any element of string array S
%   contains PATTERN. TF is the same size as S.
%
% This is a compatibility function that should only be added to the path
% of MATLAB versions prior to R2016b.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% try to automatically remove incorrect compat folders from the path, see https://github.com/fieldtrip/fieldtrip/issues/899

if isempty(strfind(mfilename('fullpath'), matlabroot))
  % automatic cleanup does not work when FieldTrip is installed inside the MATLAB path, see https://github.com/fieldtrip/fieldtrip/issues/1527
  
  alternatives = which(mfilename, '-all');
  if ~iscell(alternatives)
    % this is needed for octave, see https://github.com/fieldtrip/fieldtrip/pull/1171
    alternatives = {alternatives};
  end
  
  keep = true(size(alternatives));
  for i=1:numel(alternatives)
    keep(i) = keep(i) && ~any(alternatives{i}=='@');  % exclude methods from classes
    keep(i) = keep(i) && alternatives{i}(end)~='p';   % exclude precompiled files
  end
  alternatives = alternatives(keep);
  
  if exist(mfilename, 'builtin') || any(strncmp(alternatives, matlabroot, length(matlabroot)) & cellfun(@isempty, strfind(alternatives, fullfile('private', mfilename))))
    % remove this directory from the path
    p = fileparts(mfilename('fullpath'));
    warning('removing "%s" from your path, see http://bit.ly/2SPPjUS', p);
    rmpath(p);
    % call the original MATLAB function
    if exist(mfilename, 'builtin')
      [varargout{1:nargout}] = builtin(mfilename, varargin{:});
    else
      [varargout{1:nargout}] = feval(mfilename, varargin{:});
    end
    return
  end
  
end % automatic cleanup of compat directories

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is where the actual replacement code starts
% function tf = contains(s, pattern, str, boolean)

% deal with the input arguments
if nargin==1
  [s                       ] = deal(varargin{1:1});
elseif nargin==2
  [s, pattern              ] = deal(varargin{1:2});
elseif nargin==3
  [s, pattern, str         ] = deal(varargin{1:3});
elseif nargin==4
  [s, pattern, str, boolean] = deal(varargin{1:4});
else
  error('incorrect number of input arguments')
end

if ~ischar(s) && ~iscellstr(s)
  error('the input should be either a char-array or a cell-array with chars');
end

if nargin<4
  boolean = false;
end
if nargin<3
  str = 'IgnoreCase';
end
if ~strcmpi(str, 'ignorecase')
  error('incorrect third input argument, can only be ''IgnoreCase''');
end
if ~islogical(boolean)
  error('fourth input argument should be a logical scalar');
end

if ~iscellstr(s)
  s = {s};
end

if boolean
  s       = lower(s);
  pattern = lower(pattern);
end

tf = ~cellfun(@isempty, strfind(s, pattern));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deal with the output arguments

varargout = {tf};
