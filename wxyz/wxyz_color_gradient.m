function varargout = wxyz_color_gradient(varargin)

wxyzColor = {
    [0, 114, 189
    28, 130, 196
    57, 145, 204
    85, 161, 211
    113, 177, 218
    142, 192, 226
    170, 208, 233
    198, 224, 240
    227, 239, 248
    255, 255, 255]/255; % Color1

    [217, 83, 25
    221, 102, 51
    225, 121, 76
    230, 140, 102
    234, 159, 127
    238, 179, 153
    242, 198, 178
    247, 217, 204
    251, 236, 229
    255, 255, 255]/255; % Color2

    [237, 177, 32
    239, 186, 57
    241, 194, 82
    243, 203, 106
    245, 212, 131
    247, 220, 156
    249, 229, 181
    251, 238, 205
    253, 246, 230
    255, 255, 255]/255; % Color3

    [126, 47, 142
    140, 70, 155
    155, 93, 167
    169, 116, 180
    183, 139, 192
    198, 163, 205
    212, 186, 217
    226, 209, 230
    241, 232, 242
    255, 255, 255]/255; % Color4

    [119, 172, 48
    134, 181, 71
    149, 190, 94
    164, 200, 117
    179, 209, 140
    195, 218, 163
    210, 227, 186
    225, 237, 209
    240, 246, 232
    255, 255, 255]/255; % Color5

    [77, 190, 238
    97, 197, 240
    117, 204, 242
    136, 212, 244
    156, 219, 246
    176, 226, 247
    196, 233, 249
    215, 241, 251
    235, 248, 253
    255, 255, 255]/255; % Color6

    [162, 20, 47
    172, 46, 70
    183, 72, 93
    193, 98, 116
    203, 124, 139
    214, 151, 163
    224, 177, 186
    234, 203, 209
    245, 229, 232
    255, 255, 255]/255; % Color7
    };

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