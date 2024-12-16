function fft = wxyz_fftanalysis(data, fband, varargin) % , latency
% WXYZ_FFTANALYSIS This function is used to perform Fast Fourier Transform
% (FFT) analysis on the data.
% 
% This function takes data, foi, latency and padding as inputs. Return the
% calculated FFT as output.
%
% data      - It is used to calculate the raw data of FFT. The format must
%           be the result obtained after ft_preprocessing. 
% fband     - The FFT frequency band ([hp, lp]), in Hz, needs to be calculated.
% latency   - Time period used to perform FFT analysis, in seconds.
% 
% example: 
%   [fft] = wxyz_fftsanalysis(data, fband, 'latency', [0 1], 'padding', 10);
% Author: wxyz
% Version: 1.0
% Last revision date : 2024-04-15

% do the general setup of the function
ft_defaults

% Check data
if ~isfield(data, 'time') || ~isfield(data, 'trial')
    error('The data should contains a field name of ''time'' and ''trial''');
end
if numel(fband)~=2
    error('The fband should contains 2 elements');
end

% Default value
latency = ft_getopt(varargin, 'latency', []);
channel = ft_getopt(varargin, 'channel', 'meg');
method  = ft_getopt(varargin, 'method' , 'mtmfft');
taper   = ft_getopt(varargin, 'taper'  , 'hanning');
width   = ft_getopt(varargin, 'width'  , 0.1);
padding = ft_getopt(varargin, 'padding', 10);

% Do data selection if 
if ~isempty(latency)
    cfg         = [];
    cfg.latency = latency;
    tmp         = ft_selectdata(cfg, data);
else
    tmp         = data;
end

% Do FFT
cfg             = [];
cfg.channel     = channel;
cfg.method      = method;
cfg.taper       = taper;
cfg.width       = width;
cfg.output      = 'fourier';
cfg.keeptrials  = 'yes';
cfg.keeptapers  = 'yes';
cfg.pad         = padding;
cfg.foi         = fband(1):1/cfg.pad:fband(2);
fft             = ft_freqanalysis(cfg, tmp);

% Add average fft
fft.dimord      = 'rpt_chan_freq';
fft.fft         = abs(fft.fourierspctrm);
fft.pow         = fft.fft.^2;
fft.fftavg      = squeeze(mean(fft.fft, 1));
