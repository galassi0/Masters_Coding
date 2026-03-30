% Matt Galassi
% Last modified: 2025-Oct-31
%
% Code to create and plot FFT of EEG data, and test various windowing
% methods

%%
clear,clc
% Load data
load('hum.mat');

% Visualizing the raw data
% tiledlayout(4,1)
% nexttile
% plot(eeg)
% nexttile
% plot(eegf)
% nexttile
% plot(a)
% nexttile
% plot(b)

% Assign data you want to use
data = eeg - mean(eeg);
Fs = 256;
%% Plot Raw data

plot(eeg, DisplayName='EEG Data')

title('Raw EEG Data');
styleAxes();
xlabel('Sample Number (n)');
ylabel('EEG (\muV)');
xlim([0 numel(eeg)])

%% Polar and rectangular plots

t = 0:1/Fs:2;  % Time vector for 2 seconds of data (length will be 2001 points)

% Part 1: Analysis of the entire signal
N = length(data);  % Length of the signal
Y = fft(data);  % Compute FFT

% Build frequency vector (from 0 to Fs, but note it's periodic; often we plot 0 to Fs/2 for one-sided)
f = (0:N-1) * (Fs / N);  % Frequency vector in Hz

% Magnitude
mag = abs(Y);

% Power spectrum (periodogram estimate: |Y|^2 / N)
power = (abs(Y).^2) / N;

% Phase
phase = angle(Y);

% Reconstruct original signal using inverse FFT
reconstructed = ifft(Y);

% Visualize Rectangular vs Polar
% figure(4); % Rectancular
% plot(Y);  % One-sided magnitude
% title('EEG Signal -- Rectangular Notation');
% styleAxes();
% xlabel('Real Component (\muV)');
% ylabel('Imaginary Component (\muV)');

% Polar v1
% [x,y] = pol2cart(phase, mag);
% figure(5);
% plot(x,y);  % One-sided magnitude
% title('EEG Signal -- Polar Notation');
% styleAxes();
% xlabel('');
% ylabel('Y-coordinate');
% axis equal; % Ensures circles appear circular, not elliptical
% grid off;
% xlim([-1.2*10^6 1.2*10^6]);

% Polar v2
figure(5)
polarplot(Y)
% styleAxes()
title('Polar Notation')

%% Magnitude Plots

% Display reconstruction error (should be near zero due to numerical precision)
reconstruction_error = max(abs(data - reconstructed));
fprintf('Reconstruction error for entire signal: %e\n', reconstruction_error);

% Magnitude Plot
figure(1);
plot(f(1:floor(N/2)+1), mag(1:floor(N/2)+1), 'LineWidth',1.2, DisplayName='EEG Frequency Content');  % One-sided magnitude
title('Magnitude Spectrum of Entire Signal');
styleAxes();
xlabel('Frequency (Hz)');
ylabel('Magnitude (\muV)');

%% Analysis of a section of 256 points

section_start = 1;  % Starting index (adjust if needed)
data_section = data(section_start:section_start+255);  % 256 points
N_section = length(data_section);  % 256
Y_section = fft(data_section);

% Frequency vector for section
f_section = (0:N_section-1) * (Fs / N_section);

% Magnitude, power, phase
mag_section = abs(Y_section);
power_section = (abs(Y_section).^2) / N_section;
phase_section = angle(Y_section);

% Reconstruct
reconstructed_section = ifft(Y_section);

% FFT Plot for first 256 Points
figure(2);
plot(f_section(1:floor(N_section/2)+1), mag_section(1:floor(N_section/2)+1), 'LineWidth',1.6,DisplayName='EEG Frequency Content');
title('Magnitude Spectrum of First 256-Points');
styleAxes();
xlabel('Frequency (Hz)');
ylabel('Magnitude (\muV)');

%% Analysis of 256-point section with 1792 zeros appended (zero-padding to 2048 points)

data_padded = [data_section; zeros(1792, 1)];  % Total length 2048
N_padded = length(data_padded);  % 2048
Y_padded = fft(data_padded);

% Frequency vector for padded
f_padded = (0:N_padded-1) * (Fs / N_padded);

% Magnitude, power, phase
mag_padded = abs(Y_padded);
power_padded = (abs(Y_padded).^2) / N_padded;  % Note: For power, sometimes normalized by original N_section, but here by N_padded for consistency
phase_padded = angle(Y_padded);

% Reconstruct (will include zeros)
reconstructed_padded = ifft(Y_padded);

% Plot FFT for Zero-Padded
figure(3);
plot(f_padded(1:floor(N_padded/2)+1), mag_padded(1:floor(N_padded/2)+1), 'LineWidth',1.2,DisplayName='EEG Frequency Content');
title({'Magnitude Spectrum'},{'Zero-Padded Signal (2048 points)'});
styleAxes();
xlabel('Frequency (Hz)');
ylabel('Magnitude (\muV)');

%% Window Testing -- Grouped Plots


% Define signals
section_start = 1;
data_section = data(section_start:section_start+255);  % 256-point section
data_padded = [data_section; zeros(1792, 1)];  % Padded to 2048 points

% Desired frequency resolutions (approx 0.1 Hz, 1 Hz, 10 Hz)
target_dfs = [0.1, 1, 10];  % Hz
N_values = round(Fs ./ target_dfs);  % Window lengths: N = Fs / Δf
overlap = 0.5;  % 50% overlap for overlapping windows

% Window types
window_types = {'rectangular', 'hanning', 'bartlett'};
signals = {data, data_padded};
signal_names = {'Entire Signal', 'Padded 256-Point Section'};

% Process each signal
for s = 1:length(signals)
    signal = signals{s};
    N_signal = length(signal);
    fprintf('\nProcessing %s (N = %d)\n', signal_names{s}, N_signal);
    
    % Create separate figures for FFT and Pwelch and store handles
    fig_fft = figure('Name', sprintf('%s: FFT Magnitude Spectra', signal_names{s}), ...
        'Position', [100, 100, 800, 600]);
    hold on;
    title(sprintf('%s: FFT Magnitude Spectra', signal_names{s}));
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    
    fig_pwelch = figure('Name', sprintf('%s: Pwelch PSD (Linear)', signal_names{s}), ...
        'Position', [900, 100, 800, 600]);
    hold on;
    title(sprintf('%s: Pwelch PSD (Linear Power/Hz)', signal_names{s}));
    xlabel('Frequency (Hz)'); ylabel('Power/Frequency (Power/Hz)');

    for n_idx = 1:length(N_values)
        N_win = N_values(n_idx);  % Window length
        if N_win > N_signal
            fprintf('Skipping N=%d for %s (signal too short)\n', N_win, signal_names{s});
            continue;
        end
        df = Fs / N_win;  % Actual frequency resolution
        fprintf('Window length N=%d, Δf=%.2f Hz\n', N_win, df);
        
        for w_idx = 1:length(window_types)
            win_type = window_types{w_idx};
            % Create window
            switch win_type
                case 'rectangular'
                    win = ones(N_win, 1);
                case 'hanning'
                    win = hann(N_win);
                case 'bartlett'
                    win = bartlett(N_win);
            end
            
            % Non-overlapping FFT
            num_windows = floor(N_signal / N_win);
            if num_windows == 0
                continue;
            end
            mag_avg = zeros(N_win, 1);
            for i = 1:num_windows
                idx = (i-1)*N_win + 1:i*N_win;
                segment = signal(idx) .* win;
                Y = fft(segment);
                mag_avg = mag_avg + abs(Y) / num_windows;
            end
            f = (0:N_win-1) * (Fs / N_win);  % Frequency vector
            figure(fig_fft);  % Use stored handle
            plot(f(1:floor(N_win/2)+1), mag_avg(1:floor(N_win/2)+1), ...
                'DisplayName', sprintf('%s, N=%d, Non-Overlap', win_type, N_win));
            
            % Overlapping FFT (50%)
            overlap_samples = floor(N_win * overlap);
            num_windows = floor((N_signal - N_win) / (N_win - overlap_samples) + 1);
            mag_avg = zeros(N_win, 1);
            for i = 1:num_windows
                idx = (i-1)*(N_win - overlap_samples) + 1:(i-1)*(N_win - overlap_samples) + N_win;
                segment = signal(idx) .* win;
                Y = fft(segment);
                mag_avg = mag_avg + abs(Y) / num_windows;
            end
            figure(fig_fft);  % Use stored handle
            plot(f(1:floor(N_win/2)+1), mag_avg(1:floor(N_win/2)+1), '--', ...
                'DisplayName', sprintf('%s, N=%d, 50%% Overlap', win_type, N_win));
            
            % Pwelch PSD (linear scale)
            [Pxx, f_pwelch] = pwelch(signal, win, overlap_samples, N_win, Fs);
            figure(fig_pwelch);  % Use stored handle
            plot(f_pwelch, Pxx, 'DisplayName', sprintf('%s, N=%d', win_type, N_win));
        end
    end
    % Finalize each figure
    figure(fig_fft);
    legend('show'); hold off;
    figure(fig_pwelch);
    legend('show'); hold off;
end



%% 

% -------------------------------- Processed Plots for Presentation  -----------------------------%


%% Plot Combined 2 (Main Script)
% --- User-Defined Variables (Assuming Fs and data are defined elsewhere) ---
% Fs = 500; % Example: Sampling Frequency (Hz)
% data = randn(2000, 1); % Example: Data vector

% Define signals
section_start = 1;
% 256-point section of EEG data
data_section = data(section_start:section_start+255);
% Zero-padded to 2048 points (256 + 1792 = 2048)
data_padded = [data_section; zeros(1792, 1)];

% Assume 'data' is the full, original signal
N_full_data = length(data); % Get the length of the *true* full signal

% Desired window length values (N = Fs / Δf)
target_dfs = [0.1, 1, 10]; % Hz
N_values = round(Fs ./ target_dfs);
overlap_factor = 0.5; % 50% overlap factor

% Window types
window_types = {'rectangular', 'hanning', 'bartlett'};
signals = {data, data_padded};
% Use descriptive names for the two signal variables
signal_names_base = {'Original Signal (Length=ALL)', 'Padded Section (Length=2048)'}; 
method_names = {'Non-Overlap FFT', '50% Overlap FFT', 'Pwelch PSD'};

% --- Global Figure Counter (for organizing figures) ---
fig_counter = 1;

% --- Process Each Signal and N-Value ---
for s = 1:length(signals)
    signal = signals{s};
    N_signal = length(signal);
    signal_label_base = signal_names_base{s}; % e.g., 'Original Signal (Length=ALL)'

    for n_idx = 1:length(N_values)
        N_win = N_values(n_idx); % Current Window length
        overlap_samples = floor(N_win * overlap_factor);
        df = Fs / N_win; % Actual frequency resolution
        
        % Skip if window is longer than the whole signal
        if N_win > N_signal
             fprintf('Skipping N=%d for %s (signal too short)\n', N_win, signal_label_base);
             continue;
        end
        
        % For the Padded Signal, typically skip windows larger than the original data length (256)
        if s == 2 && N_win > 256
            continue;
        end
        
        if s == 1 && N_win == N_full_data
            % Case 1: Processing the entire original signal (no windowing/averaging)
            current_signal_label = 'FULL Original Signal';
        elseif s == 1 && N_win < N_full_data
            % Case 2: Processing the original signal using sections (segments/windows)
            current_signal_label = sprintf('Original Signal (Windowed)');
        elseif s == 2
            % Case 3: Processing the 256-point data padded to 2048 points
            current_signal_label = '256-Point Padded Data';
        else
            current_signal_label = signal_label_base;
        end
        
        % --- CREATE FIGURES FOR THE CURRENT N-VALUE/DF HERE ---
        
        % Generate the main title common to all three methods for this N-value
        main_title = sprintf('%s, N=%d (\\Deltaf=%.1fHz)', current_signal_label, N_win, df);
        
        % Define the subtitle for each method
        subtitles = {'Non-Overlap FFT', '50% Overlap FFT', 'Pwelch PSD'};
        
        fig_handles = cell(1, 3);
        
        for m = 1:3
            method_subtitle = subtitles{m};
            
            % Create figure and set main title
            fig_handles{m} = figure('Name', sprintf('Fig %d: %s - %s', fig_counter + m - 1, main_title, method_subtitle));
            sgtitle(main_title, 'FontWeight', 'bold'); % Main title above all axes
            
            % Create a subplot to add the method subtitle
            ax = subplot(1, 1, 1);
            title(method_subtitle); 
            
            if m < 3
                ylabel('EEG (\muV)');
            else
                ylabel('Power/Frequency (Power/Hz)');
            end
            xlabel('Frequency (Hz)');
            hold on;
            grid on;
        end
        
        % Assign specific handles for clarity
        fig_fft_non_overlap = fig_handles{1};
        fig_fft_overlap = fig_handles{2};
        fig_pwelch = fig_handles{3};
        
        % --- Process Window Types and Plot to Dedicated Figures ---
        for w_idx = 1:length(window_types)
            win_type = window_types{w_idx};
            
            % Create window
            switch win_type
                case 'rectangular'
                    win = ones(N_win, 1);
                case 'hanning'
                    win = hann(N_win);
                case 'bartlett'
                    win = bartlett(N_win);
            end
            % 1. Non-overlapping FFT Averaging
            num_windows = floor(N_signal / N_win);
            if num_windows > 0
                mag_avg = zeros(N_win, 1);
                for i = 1:num_windows
                    idx = (i-1)*N_win + 1:i*N_win;
                    segment = signal(idx) .* win;
                    Y = fft(segment);
                    mag_avg = mag_avg + abs(Y) / num_windows;
                end
                f = (0:N_win-1) * (Fs / N_win); % Frequency vector
                figure(fig_fft_non_overlap);
                plot(f(1:floor(N_win/2)+1), mag_avg(1:floor(N_win/2)+1), ...
                    'DisplayName', sprintf('%s', win_type), 'LineWidth', 1.4);
            end
            % 2. Overlapping (50%) FFT Averaging
            step_size = N_win - overlap_samples;
            num_windows = floor((N_signal - N_win) / step_size) + 1;
            if num_windows > 0
                mag_avg = zeros(N_win, 1);
                for i = 1:num_windows
                    start_idx = (i-1)*step_size + 1;
                    end_idx = start_idx + N_win - 1;
                    if end_idx > N_signal, break; end 
                    segment = signal(start_idx:end_idx) .* win;
                    Y = fft(segment);
                    mag_avg = mag_avg + abs(Y) / num_windows;
                end
                
                figure(fig_fft_overlap);
                plot(f(1:floor(N_win/2)+1), mag_avg(1:floor(N_win/2)+1), ...
                    'DisplayName', sprintf('%s', win_type), 'LineWidth', 1.4);
            end
            
            % 3. Pwelch PSD (50% Overlap)
            [Pxx, f_pwelch] = pwelch(signal, win, overlap_samples, N_signal, Fs);
            
            figure(fig_pwelch);
            plot(f_pwelch, Pxx, 'DisplayName', sprintf('%s', win_type), 'LineWidth', 1.4);
        end % end window_types loop
        
        % --- Finalize and Apply styleAxes for the 3 figures for the current N-value ---
        for m = 1:3
            figure(fig_handles{m});
            styleAxes(1); % Applied here!
            hold off;
        end
        % Increment the figure counter for the next set of plots
        fig_counter = fig_counter + 3;
    end % end N_values loop
end % end signals loop


%% Shared Axis Formatting Function

function styleAxes(legtitle)
    ax = gca;
    ax.Box = 'off';            % Remove surrounding box
    ax.FontSize = 20;          % Larger font for readability
    ax.LineWidth = 1.5;        % Thicker axis lines
    ax.TickLength = [0.005 0.005]; % Shorter tick marks
    grid off;                  % No grid in 2D plots
    if nargin >= 1
        h = legend('location','northeastoutside', 'Box', 'off');
        title(h, 'Window Type');
    else
        legend('location','northeastoutside', 'Box', 'off')
    end
end

