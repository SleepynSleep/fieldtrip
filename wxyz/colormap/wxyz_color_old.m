function varargout = wxyz_color_old(varargin)

wxyzColor = func_getColor();

%%
code = 0;
if nargin == 0 % return all color
    varargout{1} = wxyzColor;
elseif nargin == 1
    if isnumeric(varargin{1}) && numel(varargin{1})==1 && varargin{1} >= 1 && varargin{1} <= length(wxyzColor)
        varargout{1} = wxyzColor{varargin{1}};
    else
        error(['The intput varaiable should be less than ' num2str(length(wxyzColor))]);
    end
elseif nargin == 2
    if isnumeric(varargin{1}) && numel(varargin{1})==1 && isnumeric(varargin{2}) && all(varargin{2}<=size(wxyzColor{varargin{1}},1))
        varargout{1} = wxyzColor{varargin{1}}(varargin{2}, :);
    else
        error('Please check the intput varaiable');
    end
else
    error('The intput varaiable should be given and less than 2.')
end

end


function color = func_getColor()

color = {
    [016 070 128;
    049 124 183;
    109 173 209;
    182 215 232;
    233 241 244;
    251 227 213;
    246 178 147;
    220 109 087;
    183 034 048;
    109 001 031]; % Color1

    [022 048 074;
    019 103 131;
    033 158 188;
    144 201 231;
    254 183 005;
    255 158 002;
    250 134 000]; % Color2

    [002 038 062;
    003 050 080;
    013 076 109;
    115 186 214;
    239 065 067;
    191 030 046;
    196 050 063]; % Color3

    [002 048 071;
    018 104 131;
    039 158 188;
    144 201 230;
    252 158 127;
    247 091 065;
    213 033 032]; % Color4

    [038 070 083;
    040 114 113;
    042 157 140;
    138 176 125;
    233 196 107;
    243 162 097;
    230 111 081]; % Color5

    [255 255 255;
    251 227 213;
    246 178 147;
    220 109 087;
    183 034 048;
    109 001 031]; % Color6

    [016 070 128;
    049 124 183;
    109 173 209;
    182 215 232;
    233 241 244;
    255 255 255]; % Color7
    
    
    [184 219 179;
    114 176 99;
    113 154 172;
    226 145 53;
    148 198 205;
    74 95 126]; % color 8
    
    };


end