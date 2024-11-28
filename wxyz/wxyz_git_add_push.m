function wxyz_git_add_push(varargin)
if nargin == 1 && (ischar(varargin{1})||isstring(varargin{1}))
    commit = varargin{1};
elseif nargin == 0
    commit = "add & push by SleepynSleep using Matlab";
else
    error('Please check your input! The input should be string');
end
!git add .
% !git commit -m "add & push by SleepynSleep using Matlab"
system(strcat('git commit -m "', commit, '"'))
!git push -u origin master
end