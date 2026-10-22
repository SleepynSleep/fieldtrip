function erds = wxyz_erdsanalysis(data, frequency, baseline, varargin)
% WXYZ_ERDSANALYSIS Perform ERD/ERS processing on epoched M/EEG data.
%
% Use as
%   erds = wxyz_erdsanalysis(data, frequency, baseline)
%   erds = wxyz_erdsanalysis(..., 'powermethod', 'totalpower')
%   erds = wxyz_erdsanalysis(..., 'baselinetype', 'db')
%
% Required inputs
%   data      - Epoched raw data returned by FT_PREPROCESSING.
%   frequency - Two-element frequency band [low high], in Hz.
%   baseline  - Two-element baseline interval [start end], in seconds.
%
% Optional key-value pairs
%   method       - Frequency method. Only 'bandpass' is currently supported.
%                  Default: 'bandpass'.
%   powermethod  - 'intertrialvariance' removes the trial-average waveform
%                  before calculating power; 'totalpower' calculates the
%                  classical mean squared band-pass signal. Default:
%                  'intertrialvariance'.
%   baselinetype - 'percent', 'db', or 'zscore'. Default: 'percent'.
%   smooth       - Moving-mean window length in samples. Set to 0 to disable
%                  smoothing. Default: one second (data.fsample samples).
%   erdslength   - Optional output interval [start end], in seconds. Filtering
%                  is performed on the full trials before this interval is
%                  selected, which helps to reduce filter-edge effects.
%
% The sign convention for 'percent' is negative ERD and positive ERS:
%   100 * (power - baselinePower) / baselinePower
%
% Author: wxyz
% Version: 1.1
% Last revision date: 2026-07-24

% Do the general FieldTrip setup.
ft_defaults

% Check the required inputs.
if ~isstruct(data) || ~isfield(data, 'time') || ~isfield(data, 'trial') || ...
        ~isfield(data, 'fsample') || isempty(data.trial)
    error('Data must be a nonempty FieldTrip raw structure with time, trial, and fsample fields.');
end
if ~isnumeric(frequency) || numel(frequency) ~= 2 || ...
        any(~isfinite(frequency)) || frequency(1) <= 0 || ...
        frequency(1) >= frequency(2) || frequency(2) >= data.fsample/2
    error('Frequency must be [low high] within the interval (0, Nyquist).');
end
if ~isnumeric(baseline) || numel(baseline) ~= 2 || ...
        any(~isfinite(baseline)) || baseline(1) >= baseline(2)
    error('Baseline must be a finite, increasing interval [start end].');
end

nTrial = numel(data.trial);
if numel(data.time) ~= nTrial
    error('Data.time and data.trial must contain the same number of trials.');
end
trialSize = size(data.trial{1});
for iTrial = 1:nTrial
    if ~isnumeric(data.trial{iTrial}) || ...
            ~isequal(size(data.trial{iTrial}), trialSize) || ...
            numel(data.time{iTrial}) ~= trialSize(2) || ...
            ~isequal(data.time{iTrial}(:), data.time{1}(:))
        error('All trials must have identical numeric data dimensions and time axes.');
    end
    if any(~isfinite(data.trial{iTrial}(:)))
        error('Trials containing NaN or Inf are not supported because filtering spreads them.');
    end
end

% Read options.
method = lower(string(ft_getopt(varargin, 'method', 'bandpass')));
powerMethod = lower(string(ft_getopt(varargin, 'powermethod', 'intertrialvariance')));
baselineType = lower(string(ft_getopt(varargin, 'baselinetype', 'percent')));
smoothWinLength = ft_getopt(varargin, 'smooth', round(data.fsample));
erdslength = ft_getopt(varargin, 'erdslength', []);

if method ~= "bandpass"
    error('Only method=''bandpass'' is currently implemented.');
end
if ~ismember(powerMethod, ["intertrialvariance", "totalpower"])
    error('Powermethod must be ''intertrialvariance'' or ''totalpower''.');
end
if ~ismember(baselineType, ["percent", "db", "zscore"])
    error('Baselinetype must be ''percent'', ''db'', or ''zscore''.');
end
if ~isnumeric(smoothWinLength) || ~isscalar(smoothWinLength) || ...
        ~isfinite(smoothWinLength) || smoothWinLength < 0 || ...
        smoothWinLength ~= fix(smoothWinLength)
    error('Smooth must be a nonnegative integer number of samples.');
end
if ~isempty(erdslength) && (~isnumeric(erdslength) || numel(erdslength) ~= 2 || ...
        any(~isfinite(erdslength)) || erdslength(1) >= erdslength(2))
    error('Erdslength must be empty or a finite, increasing interval [start end].');
end

if powerMethod == "intertrialvariance" && nTrial < 2
    error('Inter-trial variance requires at least two trials.');
end

% Band-pass filter the full epochs. FieldTrip defaults to a two-pass,
% zero-phase Butterworth filter; filtering before cropping preserves padding.
filterOrder = 4;
datatmpfilt = cellfun(@(x) ft_preproc_bandpassfilter( ...
    x, data.fsample, frequency, filterOrder), data.trial, ...
    'UniformOutput', false);

% Optionally select the output interval after filtering.
timeVec = data.time{1};
if ~isempty(erdslength)
    if erdslength(1) < timeVec(1) || erdslength(2) > timeVec(end)
        error('Erdslength must lie within the trial time interval.');
    end
    datatmp = data;
    datatmp.trial = datatmpfilt;
    cfg = [];
    cfg.toilim = erdslength;
    datatmp = ft_redefinetrial(cfg, datatmp);
    datatmpfilt = datatmp.trial;
    timeVec = datatmp.time{1};
end

% Calculate either induced inter-trial variance or classical total power.
trialData = cat(3, datatmpfilt{:});
switch powerMethod
    case "intertrialvariance"
        trialMean = mean(trialData, 3);
        trialPower = sum((trialData - trialMean).^2, 3) / (nTrial - 1);
    case "totalpower"
        trialPower = mean(trialData.^2, 3);
end

% Smooth the power time course.
if smoothWinLength > 1
    trialPower = smoothdata(trialPower, 2, 'movmean', smoothWinLength);
end

% Use time values from the actual output interval, avoiding index mismatch
% when erdslength is specified.
baselineIdx = timeVec >= baseline(1) & timeVec <= baseline(2);
if nnz(baselineIdx) < 2
    error('Baseline must contain at least two samples in the output interval.');
end
baselinePower = mean(trialPower(:, baselineIdx), 2);

% Apply baseline normalization.
switch baselineType
    case "percent"
        if any(baselinePower <= 0)
            error('Percent normalization requires positive baseline power.');
        end
        avgmat = (trialPower - baselinePower) ./ baselinePower * 100;
        outputUnit = 'percent';
    case "db"
        if any(baselinePower <= 0) || any(trialPower(:) <= 0)
            error('dB normalization requires strictly positive power.');
        end
        avgmat = 10 * log10(trialPower ./ baselinePower);
        outputUnit = 'dB';
    case "zscore"
        baselineStd = std(trialPower(:, baselineIdx), 1, 2);
        if any(baselineStd <= 0)
            error('Z-score normalization requires nonzero baseline standard deviation.');
        end
        avgmat = (trialPower - baselinePower) ./ baselineStd;
        outputUnit = 'z-score';
end

% Collect the results.
erds = keepfields(data, {'label', 'trialinfo', 'fsample', 'grad', 'elec'});
erds.time = timeVec;
erds.avg = avgmat;
erds.dimord = 'chan_time';
erds.config.method = char(method);
erds.config.powermethod = char(powerMethod);
erds.config.baselinetype = char(baselineType);
erds.config.frequency = frequency;
erds.config.baseline = baseline;
erds.config.smooth = smoothWinLength;
erds.config.smoothseconds = smoothWinLength / data.fsample;
erds.config.erdslength = erdslength;
erds.config.filtertype = 'butterworth';
erds.config.filterorder = filterOrder;
erds.config.filterdirection = 'twopass';
erds.config.outputunit = outputUnit;
