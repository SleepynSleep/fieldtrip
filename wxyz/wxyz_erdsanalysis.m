function erds = wxyz_erdsanalysis(data, frequency, baseline, varargin)
% WXYZ_ERDSANALYSIS Perform ERD/ERS processing on epoched M/EEG data.
%
% Use as
%   erds = wxyz_erdsanalysis(data, frequency, baseline)
%   erds = wxyz_erdsanalysis(..., 'powermethod', 'totalpower')
%   erds = wxyz_erdsanalysis(..., 'baselinetype', 'db')
%   erds = wxyz_erdsanalysis(..., 'method', 'wavelet')
%
% Required inputs
%   data      - Epoched raw data returned by FT_PREPROCESSING.
%   frequency - Two-element frequency band [low high], in Hz.
%   baseline  - Two-element baseline interval [start end], in seconds.
%
% Optional key-value pairs
%   method       - 'bandpass', 'hilbert', 'wavelet', 'stft', or
%                  'mtmconvol'. Default: 'bandpass'.
%   powermethod  - 'intertrialvariance' removes the trial-average waveform
%                  before calculating power; 'totalpower' includes induced
%                  and evoked activity; 'evokedpower' contains the power of
%                  the trial-average waveform. Default: 'intertrialvariance'.
%   baselinetype - 'percent', 'db', or 'zscore'. Default: 'percent'.
%   smooth       - Moving-mean window length in samples. Set to 0 to disable
%                  smoothing. The default is one second for bandpass and
%                  Hilbert, and 0 for time-frequency methods.
%   erdslength   - Optional output interval [start end], in seconds. Filtering
%                  or time-frequency analysis is performed before selecting
%                  this interval, which helps to reduce edge effects.
%   foi          - Frequencies of interest for wavelet, STFT, or multitaper.
%                  Default: approximately 1-Hz steps within frequency.
%   width        - Number of Morlet-wavelet cycles. Default: 7.
%   timewindow   - STFT/multitaper window length in seconds. May be scalar or
%                  one value per frequency. Default: 0.5.
%   tapsmofrq    - Multitaper spectral smoothing in Hz. Default: 3.
%
% The sign convention for 'percent' is negative ERD and positive ERS:
%   100 * (power - baselinePower) / baselinePower
%
% Author: wxyz
% The output fields total, evoked, and induced contain the three normalized
% power components. AVG contains the component selected by powermethod.
% For wavelet, STFT, and multitaper methods, ERDS.ERSP additionally contains
% frequency-resolved total, evoked, induced, and selected ERSP maps with
% dimension chan_freq_time.
%
% Version: 2.1
% Last revision date: 2026-07-27

    % Do the general FieldTrip setup.
    ft_defaults

    % Check the required inputs.
    if ~isstruct(data) || ~isfield(data, 'time') || ~isfield(data, 'trial') || ~isfield(data, 'fsample') || isempty(data.trial)
        error('Data must be a nonempty FieldTrip raw structure with time, trial, and fsample fields.');
    end
    if ~isnumeric(frequency) || numel(frequency) ~= 2 || any(~isfinite(frequency)) || frequency(1) <= 0 || frequency(1) >= frequency(2) || frequency(2) >= data.fsample/2
        error('Frequency must be [low high] within the interval (0, Nyquist).');
    end
    if ~isnumeric(baseline) || numel(baseline) ~= 2 || any(~isfinite(baseline)) || baseline(1) >= baseline(2)
        error('Baseline must be a finite, increasing interval [start end].');
    end

    nTrial = numel(data.trial);
    if numel(data.time) ~= nTrial
        error('Data.time and data.trial must contain the same number of trials.');
    end
    trialSize = size(data.trial{1});
    for iTrial = 1:nTrial
        if ~isnumeric(data.trial{iTrial}) || ~isequal(size(data.trial{iTrial}), trialSize) || numel(data.time{iTrial}) ~= trialSize(2) || ~isequal(data.time{iTrial}(:), data.time{1}(:))
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
    smoothWinLength = ft_getopt(varargin, 'smooth', []);
    erdslength = ft_getopt(varargin, 'erdslength', []);
    foi = ft_getopt(varargin, 'foi', []);
    waveletWidth = ft_getopt(varargin, 'width', 7);
    timeWindow = ft_getopt(varargin, 'timewindow', 0.5);
    taperSmoothing = ft_getopt(varargin, 'tapsmofrq', 3);

    if ~ismember(method, ["bandpass", "hilbert", "wavelet", "stft", "mtmconvol"])
        error('Method must be ''bandpass'', ''hilbert'', ''wavelet'', ''stft'', or ''mtmconvol''.');
    end
    if ~ismember(powerMethod, ["intertrialvariance", "totalpower", "evokedpower"])
        error('Powermethod must be ''intertrialvariance'', ''totalpower'', or ''evokedpower''.');
    end
    if ~ismember(baselineType, ["percent", "db", "zscore"])
        error('Baselinetype must be ''percent'', ''db'', or ''zscore''.');
    end
    if isempty(smoothWinLength)
        if ismember(method, ["wavelet", "stft", "mtmconvol"])
            smoothWinLength = 0;
        else
            smoothWinLength = round(data.fsample);
        end
    end
    if ~isnumeric(smoothWinLength) || ~isscalar(smoothWinLength) || ~isfinite(smoothWinLength) || smoothWinLength < 0 || smoothWinLength ~= fix(smoothWinLength)
        error('Smooth must be a nonnegative integer number of samples.');
    end
    if ~isempty(erdslength) && (~isnumeric(erdslength) || numel(erdslength) ~= 2 || any(~isfinite(erdslength)) || erdslength(1) >= erdslength(2))
        error('Erdslength must be empty or a finite, increasing interval [start end].');
    end

    if nTrial < 2
        error('Inter-trial variance requires at least two trials.');
    end

    % Calculate total, evoked, and induced power on the full epochs.
    filterOrder = 4;
    trialMean = mean(cat(3, data.trial{:}), 3);
    hasERSP = false;
    switch method
        case {"bandpass", "hilbert"}
            filtered = cellfun(@(x) ft_preproc_bandpassfilter( x, data.fsample, frequency, filterOrder), data.trial, 'UniformOutput', false);
            if method == "hilbert"
                filtered = cellfun(@(x) hilbert(x.').', filtered, 'UniformOutput', false);
            end

            trialData = cat(3, filtered{:});
            meanData = mean(trialData, 3);
            totalPower = mean(abs(trialData).^2, 3);
            evokedPower = abs(meanData).^2;
            inducedPower = sum(abs(trialData - meanData).^2, 3) / (nTrial - 1);
            timeVec = data.time{1};
            actualFoi = frequency;

        case {"wavelet", "stft", "mtmconvol"}
            if isempty(foi)
                nFrequency = max(2, round(diff(frequency)) + 1);
                foi = linspace(frequency(1), frequency(2), nFrequency);
            end
            if ~isnumeric(foi) || isempty(foi) || any(~isfinite(foi)) || any(foi < frequency(1)) || any(foi > frequency(2))
                error('Foi must contain finite frequencies within the requested frequency band.');
            end
            foi = foi(:)';

            cfg = [];
            cfg.output = 'pow';
            cfg.keeptrials = 'yes';
            cfg.foi = foi;
            cfg.toi = data.time{1};
            if method == "wavelet"
                if ~isnumeric(waveletWidth) || ~isscalar(waveletWidth) || ~isfinite(waveletWidth) || waveletWidth <= 0
                    error('Width must be a positive scalar.');
                end
                cfg.method = 'wavelet';
                cfg.width = waveletWidth;
            else
                if ~isnumeric(timeWindow) || isempty(timeWindow) || any(~isfinite(timeWindow)) || any(timeWindow <= 0) || ~(isscalar(timeWindow) || numel(timeWindow) == numel(foi))
                    error('Timewindow must be positive and scalar or match the number of frequencies.');
                end
                cfg.method = 'mtmconvol';
                if isscalar(timeWindow)
                    cfg.t_ftimwin = repmat(timeWindow, 1, numel(foi));
                else
                    cfg.t_ftimwin = timeWindow(:)';
                end
                if method == "stft"
                    cfg.taper = 'hanning';
                else
                    if ~isnumeric(taperSmoothing) || isempty(taperSmoothing) || any(~isfinite(taperSmoothing)) || any(taperSmoothing <= 0) || ~(isscalar(taperSmoothing) || numel(taperSmoothing) == numel(foi))
                        error('Tapsmofrq must be positive and scalar or match the number of frequencies.');
                    end
                    cfg.taper = 'dpss';
                    if isscalar(taperSmoothing)
                        cfg.tapsmofrq = repmat(taperSmoothing, 1, numel(foi));
                    else
                        cfg.tapsmofrq = taperSmoothing(:)';
                    end
                end
            end

            freqTotal = ft_freqanalysis(cfg, data);

            dataEvoked = data;
            dataEvoked.trial = {trialMean};
            dataEvoked.time = data.time(1);
            if isfield(dataEvoked, 'trialinfo')
                dataEvoked = rmfield(dataEvoked, 'trialinfo');
            end
            if isfield(dataEvoked, 'sampleinfo')
                dataEvoked = rmfield(dataEvoked, 'sampleinfo');
            end
            cfg.keeptrials = 'no';
            freqEvoked = ft_freqanalysis(cfg, dataEvoked);

            dataInduced = data;
            dataInduced.trial = cellfun(@(x) x - trialMean, data.trial, 'UniformOutput', false);
            cfg.keeptrials = 'yes';
            freqInduced = ft_freqanalysis(cfg, dataInduced);

            nChannel = trialSize(1);
            nFreq = numel(freqTotal.freq);
            nTime = numel(freqTotal.time);
            totalERSPPower = mean(freqTotal.powspctrm, 1);
            totalERSPPower = reshape(totalERSPPower, nChannel, nFreq, nTime);
            evokedERSPPower = reshape(freqEvoked.powspctrm, nChannel, nFreq, nTime);
            inducedERSPPower = mean(freqInduced.powspctrm, 1);
            inducedERSPPower = inducedERSPPower * nTrial / (nTrial - 1);
            inducedERSPPower = reshape(inducedERSPPower, nChannel, nFreq, nTime);

            totalPower = reshape(mean(totalERSPPower, 2), nChannel, nTime);
            evokedPower = reshape(mean(evokedERSPPower, 2), nChannel, nTime);
            inducedPower = reshape(mean(inducedERSPPower, 2), nChannel, nTime);
            timeVec = freqTotal.time;
            actualFoi = freqTotal.freq;
            hasERSP = true;
    end

    % Optionally select the output interval after spectral estimation.
    if ~isempty(erdslength)
        if erdslength(1) < timeVec(1) || erdslength(2) > timeVec(end)
            error('Erdslength must lie within the available output time interval.');
        end
        outputIdx = timeVec >= erdslength(1) & timeVec <= erdslength(2);
        timeVec = timeVec(outputIdx);
        totalPower = totalPower(:, outputIdx);
        evokedPower = evokedPower(:, outputIdx);
        inducedPower = inducedPower(:, outputIdx);
        if hasERSP
            totalERSPPower = totalERSPPower(:, :, outputIdx);
            evokedERSPPower = evokedERSPPower(:, :, outputIdx);
            inducedERSPPower = inducedERSPPower(:, :, outputIdx);
        end
    end

    % Smooth the three power time courses.
    if smoothWinLength > 1
        totalPower = smoothdata(totalPower, 2, 'movmean', smoothWinLength);
        evokedPower = smoothdata(evokedPower, 2, 'movmean', smoothWinLength);
        inducedPower = smoothdata(inducedPower, 2, 'movmean', smoothWinLength);
        if hasERSP
            totalERSPPower = smoothdata(totalERSPPower, 3, 'movmean', smoothWinLength);
            evokedERSPPower = smoothdata(evokedERSPPower, 3, 'movmean', smoothWinLength);
            inducedERSPPower = smoothdata(inducedERSPPower, 3, 'movmean', smoothWinLength);
        end
    end

    % Apply the same baseline convention separately to all three components.
    baselineIdx = timeVec >= baseline(1) & timeVec <= baseline(2);
    if nnz(baselineIdx) < 2
        error('Baseline must contain at least two samples in the output interval.');
    end
    totalERDS = normalizePower(totalPower, baselineIdx, baselineType);
    evokedERDS = normalizePower(evokedPower, baselineIdx, baselineType);
    inducedERDS = normalizePower(inducedPower, baselineIdx, baselineType);
    if hasERSP
        totalERSP = normalizePower(totalERSPPower, baselineIdx, baselineType);
        evokedERSP = normalizePower(evokedERSPPower, baselineIdx, baselineType);
        inducedERSP = normalizePower(inducedERSPPower, baselineIdx, baselineType);
    end

    switch powerMethod
        case "intertrialvariance"
            avgmat = inducedERDS;
            if hasERSP
                selectedERSP = inducedERSP;
            end
        case "totalpower"
            avgmat = totalERDS;
            if hasERSP
                selectedERSP = totalERSP;
            end
        case "evokedpower"
            avgmat = evokedERDS;
            if hasERSP
                selectedERSP = evokedERSP;
            end
    end
    switch baselineType
        case "percent"
            outputUnit = 'percent';
        case "db"
            outputUnit = 'dB';
        case "zscore"
            outputUnit = 'z-score';
    end

    % Collect the results.
    erds = keepfields(data, {'label', 'trialinfo', 'fsample', 'grad', 'elec'});
    erds.time = timeVec;
    erds.avg = avgmat;
    erds.total = totalERDS;
    erds.evoked = evokedERDS;
    erds.induced = inducedERDS;
    erds.dimord = 'chan_time';
    if hasERSP
        erds.ersp.avg = selectedERSP;
        erds.ersp.total = totalERSP;
        erds.ersp.evoked = evokedERSP;
        erds.ersp.induced = inducedERSP;
        erds.ersp.freq = actualFoi;
        erds.ersp.time = timeVec;
        erds.ersp.dimord = 'chan_freq_time';
        erds.ersp.baselinetype = char(baselineType);
        erds.ersp.outputunit = outputUnit;
    end
    erds.config.method = char(method);
    erds.config.powermethod = char(powerMethod);
    erds.config.baselinetype = char(baselineType);
    erds.config.frequency = frequency;
    erds.config.baseline = baseline;
    erds.config.smooth = smoothWinLength;
    erds.config.smoothseconds = smoothWinLength / data.fsample;
    erds.config.erdslength = erdslength;
    erds.config.foi = actualFoi;
    if ismember(method, ["bandpass", "hilbert"])
        erds.config.filtertype = 'butterworth';
        erds.config.filterorder = filterOrder;
        erds.config.filterdirection = 'twopass';
    elseif method == "wavelet"
        erds.config.width = waveletWidth;
    else
        erds.config.timewindow = timeWindow;
        if method == "stft"
            erds.config.taper = 'hanning';
        else
            erds.config.taper = 'dpss';
            erds.config.tapsmofrq = taperSmoothing;
        end
    end
    erds.config.outputunit = outputUnit;

end

function normalizedPower = normalizePower(power, baselineIdx, baselineType)
    % Normalize one power component relative to its own baseline.
    if ismatrix(power)
        timeDimension = 2;
        baselineMean = mean(power(:, baselineIdx), timeDimension);
    else
        timeDimension = 3;
        baselineMean = mean(power(:, :, baselineIdx), timeDimension);
    end
    if any(~isfinite(baselineMean(:))) || any(baselineMean(:) <= 0)
        error('Baseline power must be finite and positive.');
    end

    switch baselineType
        case "percent"
            normalizedPower = (power - baselineMean) ./ baselineMean * 100;
        case "db"
            normalizedPower = 10 * log10(power ./ baselineMean);
        case "zscore"
            if ismatrix(power)
                baselineStd = std(power(:, baselineIdx), 1, timeDimension);
            else
                baselineStd = std(power(:, :, baselineIdx), 1, timeDimension);
            end
            if any(~isfinite(baselineStd(:))) || any(baselineStd(:) <= 0)
                error('Z-score normalization requires nonzero baseline standard deviation.');
            end
            normalizedPower = (power - baselineMean) ./ baselineStd;
    end
end
