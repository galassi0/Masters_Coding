% Author: Matt Galassi
% Date created: September 16th 2025
% 
% A learning code for 501
% Testing personal and matlab functions when interpreting EMG data.
%
%

clear,clc;
[p1_t, p1_trig, p1_fp, p1_flex, p1_ext] = extractPunch('Matt_Trials.mat');

numCols = size(p1_flex,2);
numTrials = size(p1_flex,1);

p1_flex = p1_flex.*1000;

% A). Compare My Mean,STD,Var to matlabs:

mean_my = zeros(numTrials,1);
mean_matlab = zeros(numTrials,1);
std_my = zeros(numTrials,1);
std_matlab = zeros(numTrials,1);
var_my = zeros(numTrials,1);
var_matlab = zeros(numTrials,1);

for i = 1:size(p1_flex,1) %number of trials
    mean_my(i) = sum(p1_flex(i,:))/numel(p1_flex(i,:)); %grab a row, sum it, divide by its number of elements
    mean_matlab(i) = mean(p1_flex(i,:));
    
    std_my(i) = sqrt((sum((p1_flex(i,:)-mean_my(i)).^2)/(numCols-1)));
    std_matlab(i) = std(p1_flex(i,:)-mean_matlab(i));

    var_my(i) = std_my(i)^2;
    var_matlab(i) = var(p1_flex(i,:)-mean_matlab(i));
end


% B)1. Max and Min of t=0.2:0.3sec, whole trial, and when using a 100ms window. 
% Can uncomment the other windowsize and filenames_window to do 50ms as well.

% windowsize = [100,50];
% filenames_window = {'win100ms', 'win50ms'};
windowsize = 100;
filenames_window = {'win100ms'};
filenames_muscles = {"flex", "ext"};
data_musc = {p1_flex,p1_ext};
trialIterator = 0;

for k = 1:2 %flex+ext

    % Max and Min as a Non-Overlapping Window for Each Trial -- *not need
    % for assignment*
    for nWindowSize = 1:numel(windowsize) % iterates based on window size if I want different window sizes in same loop
        numFullWindows = floor(length(p1_flex)/windowsize(nWindowSize));
        numRemainingPoints = mod(length(p1_flex),windowsize(nWindowSize));

        if numRemainingPoints > 0
            Max.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows+1);
            Min.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows+1);
        else
            Max.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows);
            Min.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows);
        end
    
        for nTrial = 1:numTrials % number of rows is number of punch trials
            
            % Max and Min for the Each Whole Trial
            [trialmax.(filenames_muscles{k})(nTrial,1),locstrialmax(nTrial)] = max(data_musc{k}(nTrial,:));
            [trialmin.(filenames_muscles{k})(nTrial,1),locstrialmin(nTrial)] = min(data_musc{k}(nTrial,:));
           
            % Max and Min for 100-200ms segments
            [trialmax_100to200ms.(filenames_muscles{k})(nTrial,1),locsmax(nTrial)] = max(data_musc{k}(nTrial,100:200));
            [trialmin_100to200ms.(filenames_muscles{k})(nTrial,1),locsmin(nTrial)] = min(data_musc{k}(nTrial,100:200));
            locsmax(nTrial)= locsmax(nTrial)+100;
            locsmin(nTrial)= locsmin(nTrial)+100;
            for nWindow = 1:numFullWindows
                startIndex = (nWindow - 1) * windowsize(nWindowSize) + 1;
                endIndex = startIndex + windowsize(nWindowSize) - 1;
        
                % Extract the data for the current window
                windowData = data_musc{k}(nTrial,startIndex:endIndex);
        
                % Calculate the average of the current window and store it
                Max.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = max(data_musc{k}(nTrial,startIndex:endIndex));
                Min.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = min(data_musc{k}(nTrial,startIndex:endIndex));
            end

            trialIterator = trialIterator+1; %check number of trials to fix issue
            if numRemainingPoints > 0
                a = 1;
                % Calculate the start index for the final, partial window
                startIndex = numFullWindows * windowsize + 1;
    
                % Extract the remaining data
                remainingFlex = data_musc{k}(nTrial,startIndex:end);
                remainingExt = data_musc{k}(nTrial,startIndex:end);
    
                % Calculate the average of the remaining data and append it to the averages array
                Max.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = max(remainingFlex);
                Min.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = min(remainingFlex);
            end
        end
    end
end

% B)2. Absolute values of the muscle EMG per trial

for nTrial = 1:numTrials
    abs_flex(nTrial,:) = abs(p1_flex(nTrial,:));
    abs_ext(nTrial,:) = abs(p1_ext(nTrial,:));
end

% B)3. Mean, Var, and STD for Whole Trial and 50ms window.
windowsize = 50;                            % redefining window size.
filenames_window = {"win50ms"};                % redefine
for k = 1:2 %flex+ext
    for nWindowSize = 1:numel(windowsize)
        % Sliding window parameters
        numFullWindows = floor(length(p1_flex)/windowsize(nWindowSize));
        numCols = size(p1_flex,2);
        numTrials = size(p1_flex,1);
        numRemainingPoints = mod(length(p1_flex),windowsize(nWindowSize));

        % Preparing windowing storage
        if numRemainingPoints > 0
            Means.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows+1);
            Vars.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows+1);
            STD.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows+1);
        else
            Means.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows);
            Vars.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows);
            STD.(filenames_window{nWindowSize}).(filenames_muscles{k}) = zeros(numTrials, numFullWindows);
        end
    
        for nTrial = 1:numTrials % number of rows is number of punch trials
            % Full trial mean, var, std

            BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1) = mean(data_musc{k}(nTrial,1:200));

            trialMeans.(filenames_muscles{k})(nTrial,1) = mean(data_musc{k}(nTrial,:));
            trialVars.(filenames_muscles{k})(nTrial,1) = var(data_musc{k}(nTrial,:) - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1));
            trialSTD.(filenames_muscles{k})(nTrial,1) = std(data_musc{k}(nTrial,:) - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1));
            
            trialMeans_my.(filenames_muscles{k})(nTrial,1) = sum(data_musc{k}(nTrial,:))/numel(data_musc{k}(nTrial,:));
            trialSTD_my.(filenames_muscles{k})(nTrial,1) = sqrt(sum((data_musc{k}(nTrial,:) - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1)).^2)/(numel(data_musc{k}(nTrial,:))-1));
            trialVars_my.(filenames_muscles{k})(nTrial,1) = trialSTD_my.(filenames_muscles{k})(nTrial,:)^2;
            % Windowed Trial mean, var, std
            for nWindow = 1:numFullWindows
                startIndex = (nWindow - 1) * windowsize(nWindowSize) + 1;
                endIndex = startIndex + windowsize(nWindowSize) - 1;
        
                % Extract the data for the current window
                windowData = data_musc{k}(nTrial,startIndex:endIndex);
        
                % Calculate the average of the current window and store it
                Means.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = mean(data_musc{k}(nTrial,startIndex:endIndex));
                STD.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = std(data_musc{k}(nTrial,startIndex:endIndex) - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1));
                Vars.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = var(data_musc{k}(nTrial,startIndex:endIndex) - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1));
                RMS.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = rms(data_musc{k}(nTrial,startIndex:endIndex));

                Means_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = sum(data_musc{k}(nTrial,startIndex:endIndex))/numel(startIndex:endIndex);
                STD_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = sqrt(sum((data_musc{k}(nTrial,startIndex:endIndex) - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1)).^2)/(numel(startIndex:endIndex)-1));
                Vars_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) = STD_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow)^2;
                RMS_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,nWindow) =sqrt(mean(data_musc{k}(nTrial,startIndex:endIndex).^2));
            end
            trialIterator = trialIterator+1; %check number of trials to fix issue
            if numRemainingPoints > 0
                a = 1;
                % Calculate the start index for the final, partial window
                startIndex = numFullWindows * windowsize + 1;
    
                % Extract the remaining data
                remainingFlex = data_musc{k}(nTrial,startIndex:end);
                remainingExt = data_musc{k}(nTrial,startIndex:end);
    
                % Calculate the average of the remaining data and append it to the averages array
                Means.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = mean(remainingFlex);
                STD.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = std(remaininFlex);
                Vars.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = var(remainingFlex);

                Means_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = sum(remainingFlex)/numel(remainingFlex);
                STD_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = sqrt((sum(((remainingFlex - BackgroundMean_first200ms.(filenames_muscles{k})(nTrial,1))).^2)/(numel(remainingFlex)-1)));
                Vars_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end) = STD_my.(filenames_window{nWindowSize}).(filenames_muscles{k})(nTrial,end)^2;
            end
        end
    end
end

%% Compare my vs matlab

clc
regular_values = [trialMeans.flex(1), trialVars.flex(1), trialSTD.flex(1)];
my_values = [trialMeans_my.flex(1), trialVars_my.flex(1), trialSTD_my.flex(1)];% Create a new figure
figure;

% Define the x-axis labels
x_labels = {'Trial Mean', 'Trial Variance', 'Trial Std'};
x_positions = 1:numel(x_labels);

% Plot the "regular" values
plot(x_positions, regular_values, 'o', 'MarkerSize', 13, 'DisplayName', 'Matlab Functions',LineWidth=2);
hold on; % Hold the plot so you can add more data

% Plot the "my" values
plot(x_positions, my_values, 'x', 'MarkerSize', 13,  'DisplayName', 'My Calculations', LineWidth=2);
box off
grid off

% Set the categorical x-axis labels
xticks(x_positions);
xticklabels(x_labels);

% Add labels and a title
ylabel('Value');
title('Comparison of Matlab Functions vs. My Calculations');

% Add a legend to differentiate the two data series
legend('location', 'northeastoutside', 'box', 'off');
ax15 = gca;
ax15.FontSize = 18;

% Optional: Set limits and grid
xlim([0.5, numel(x_labels) + 0.5]); % Adjust x-axis limits

hold off;

t = table(trialMeans.flex(1), trialMeans_my.flex(1), trialSTD.flex(1), trialSTD_my.flex(1), trialVars.flex(1), trialVars_my.flex(1), ...
    'VariableNames', {'Matlab Mean', 'My Mean', 'Matlab Std', 'My Std', 'Matlab Variance', 'My Variance'});


%% Zero Crossings to calc Approximate Freq
clc

% Isolate the "muscle on" section, convert to mV
zerosignal = p1_flex(1,800:end)-BackgroundMean_first200ms.flex(1,1);
zero_crossing_indices = [];
% Checking for sign change
for i = 1:length(zerosignal)-1
    if zerosignal(1,i) * zerosignal(1,i+1) < 0 || (zerosignal(1,i+1) == 0)
        % A sign change indicates a zero crossing. Store the index.
        zero_crossing_indices = [zero_crossing_indices, i];
    end
end

zerosig_timevec = 800:1:1500;
maxsig = max(zerosignal)+0.1;
minsig = min(zerosignal)-0.1;

% Display the results
% disp('Zero crossings occur between these indices:');
% disp(zero_crossing_indices)

% Number of the samples divided by the amount of time in seconds
freq_est = numel(zero_crossing_indices)/(numel(zerosignal)/1000);

figure;
plot(p1_flex(1,:)-BackgroundMean_first200ms.flex(1,1), LineWidth=1);
ax1 = gca;
% Change the font size for all text in the axes
ax1.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
xline(800, '--r', LineWidth=1.2)
title('Trial 1 - Flexor Carpi Radialis EMG')
subtitle('Full Trial')
legend('FCR EMG', 'Activation Onset', 'box', 'off', 'location', 'northeastoutside')
box off
ylim([minsig maxsig]);



figure;
plot(zerosig_timevec,zerosignal,LineWidth=1);
hold on
plot(zero_crossing_indices+799,zerosignal(1,zero_crossing_indices),'.r','MarkerSize',12)
ax2 = gca;
% Change the font size for all text in the axes
ax2.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
xlim([800 1500])
legend('FCR EMG', 'Index Prior to Zero Crossing', 'box', 'off', 'location', 'northeastoutside');
title('Trial 1 - Flexor Carpi Radialis EMG')
subtitle('Active Portion')
ylim([minsig maxsig]);
box off

%% local maxima and minima

[peaks_max, peaks_max_idx] = findpeaks(data_musc{1}(1,:));
[peaks_min, peaks_min_idx] = findpeaks(-1*data_musc{1}(1,:));
peaks_min = peaks_min*-1;
max_y_peak = max(peaks_max)+0.02;
min_y_peak = min(peaks_min)-0.02;

zerosig_peak = data_musc{1}(1,800:end);
[peaks_max_sig, peaks_max_idx_sig] = findpeaks(zerosig_peak);
[peaks_min_sig, peaks_min_idx_sig] = findpeaks(-1*(zerosig_peak));
peaks_min_sig = peaks_min_sig*-1;
peaks_min_idx_sig = peaks_min_idx_sig+800;
peaks_max_idx_sig = peaks_max_idx_sig+800;


figure;
plot(data_musc{1}(1,:), LineWidth= 0.8)
hold on
plot(peaks_max_idx, peaks_max,'*r')
plot(peaks_min_idx,peaks_min, '*', 'color', [0 0.9 0])
title('Local Maxima and Minima')
subtitle('FCR EMG - Trial 1')
ax7 = gca;
ax7.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('FCR EMG','Local Maxima', 'Local Minima', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'Trial Number');
ylim([min_y_peak max_y_peak])
box off

figure;
plot(zerosig_timevec,zerosig_peak, LineWidth= 1)
hold on
plot(peaks_max_idx_sig, peaks_max_sig,'*r')
plot(peaks_min_idx_sig,peaks_min_sig, '*', 'color', [0 0.9 0])
title('Local Maxima and Minima')
subtitle('FCR EMG - Trial 1 - Active Component')
ax7 = gca;
ax7.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('FCR EMG','Local Maxima', 'Local Minima', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'Trial Number');
ylim([min_y_peak max_y_peak])
box off



%% Noise vs no noise

% This script verifies that the variance of the sum of a rectified EMG signal
% and a low-power 59 Hz and 60 Hz sine wave noise with random phase across trials
% (both with zero means) equals the sum of their individual variances.
% It uses EMG data as the signal, generates 59 Hz and 60 Hz sine wave noise with
% amplitude 0.1 and random phase per trial for each frequency, computes variances, and
% visualizes the mean rectified EMG, noise, and combined signals with ±1 STD
% shaded regions.


% --- 1. SETTINGS & DATA LOADING ---
numTrials = 10;
dataPoints = 1500;
backgroundPoints = 200; % Number of points for background noise (not used here)
samplingRate = 1000; % Hz, assuming 1500 points span 1.5 seconds
duration = dataPoints / samplingRate; % Duration in seconds (1.5 s)

% Load EMG data matrix
% Ensure data_musc and BackgroundMean_first200ms are properly defined
try
    emgData = zeros(numTrials, dataPoints);
    for i = 1:numTrials
        emgData(i,:) = data_musc{1}(i,:) - BackgroundMean_first200ms.flex(i);
    end
catch
    error('Error: Ensure data_musc and BackgroundMean_first200ms.flex are defined and have correct dimensions.');
end

% --- 2. RECTIFICATION AND NOISE GENERATION ---
% Rectify the EMG signal by taking the absolute value
rectifiedEmg = emgData;

% Ensure rectified EMG has zero mean by subtracting the mean for each trial
% This ensures the variance addition property holds exactly
for i = 1:numTrials
    rectifiedEmg(i,:) = rectifiedEmg(i,:) - mean(rectifiedEmg(i,:));
end

% Generate 59 Hz and 60 Hz sine wave noise with amplitude 0.1 and random phase per trial for each frequency
time = linspace(0, duration, dataPoints); % Time vector from 0 to 1.5 seconds
amplitude = 0.1; % Amplitude for each frequency component (variance ≈ 2 * (amplitude^2/2) = 0.01 total)
noise = zeros(numTrials, dataPoints);
for i = 1:numTrials
    phase59 = rand * 2 * pi; % Random phase for 59 Hz
    phase60 = rand * 2 * pi; % Random phase for 60 Hz
    noise(i,:) = amplitude * sin(2 * pi * 59 * time + phase59) + amplitude * sin(2 * pi * 60 * time + phase60);
end

% Compute the combined signal (rectified EMG + 59-60 Hz noise)
combined = rectifiedEmg + noise;

% --- 3. VARIANCE CALCULATIONS ---
% Compute variances across trials for each time point (dimension 1)
var_signal = var(rectifiedEmg, 0, 1); % Variance of rectified EMG
var_noise = var(noise, 0, 1); % Variance of 59-60 Hz noise
var_combined = var(combined, 0, 1); % Variance of combined signal
var_sum = var_signal + var_noise; % Sum of individual variances

% Calculate the mean absolute difference between Var(combined) and Var(signal) + Var(noise)
mean_diff = mean(abs(var_combined - var_sum));

% Display results
fprintf('Mean variance of rectified EMG across time points: %.6f\n', mean(var_signal));
fprintf('Mean variance of 59-60 Hz noise across time points: %.6f\n', mean(var_noise));
fprintf('Mean sum of variances across time points: %.6f\n', mean(var_sum));
fprintf('Mean variance of combined signal across time points: %.6f\n', mean(var_combined));
fprintf('Mean absolute difference between Var(combined) and Var(signal) + Var(noise): %.6f\n', mean_diff);

% --- 4. CALCULATE MEAN AND STD ACROSS TRIALS FOR PLOTTING ---
% Mean and STD of rectified EMG across trials (dimension 1)
meanEmg = mean(rectifiedEmg, 1);
stdEmg = std(rectifiedEmg, 0, 1);

% Mean and STD of noise across trials
meanNoise = mean(noise, 1);
stdNoise = std(noise, 0, 1);

% Mean and STD of combined signal across trials
meanCombined = mean(combined, 1);
stdCombined = std(combined, 0, 1);

% --- 5. VISUALIZATION ---
figure;

% Time vector for plotting (in milliseconds for better readability)
time_ms = time * 1000; % Convert to milliseconds

% Plot mean rectified EMG with ±1 STD shaded region
subplot(2, 1, 1);
hold on;
fill([time_ms, fliplr(time_ms)], [meanEmg + stdEmg, fliplr(meanEmg - stdEmg)], 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
plot(time_ms, meanEmg, 'b', 'LineWidth', 2);
title('10 Trial Mean EMG Signal with ±1 STD Shaded Region');

xlim([700 1400])
ylabel('EMG (mV)');
ax10 = gca;
ax10.FontSize = 18;
grid off;
box off;
hold off;

% Plot mean combined signal with ±1 STD shaded region
subplot(2, 1, 2);
hold on;
fill([time_ms, fliplr(time_ms)], [meanCombined + stdCombined, fliplr(meanCombined - stdCombined)], 'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
plot(time_ms, meanCombined, 'k', 'LineWidth', 2);
title('10 Trial Mean FCR EMG with 59 and 60Hz Noise with ±1 STD Shaded Region')
xlabel('Time (ms)');
ylabel('EMG (mV)');
xlim([700 1400])
ax11 = gca;
ax11.FontSize = 18;
grid off;
box off
hold off;

%% min max

[trialmax.(filenames_muscles{1})(1,1),locstrialmax(1)] = max(data_musc{1}(1,:));
[trialmin.(filenames_muscles{1})(1,1),locstrialmin(1)] = min(data_musc{1}(1,:));

figure
plot(locstrialmax(1),trialmax.flex(1),'o','color',[0,0.9,0],LineWidth=1)
hold on
plot(locstrialmin(1),trialmin.flex(1),'o',  'color',[0.9,0,0], LineWidth=1)
plot(locsmax(1),trialmax_100to200ms.flex(1),'*','color',[0,0.9,0],markersize=13,LineWidth=1)
plot(locsmin(1),trialmin_100to200ms.flex(1),'*','color',[0.9,0,0],markersize=13,LineWidth=1)

plot(data_musc{1}(1,:), 'color', [0,0,0.9], LineWidth=1)

title('Trial 1 - FCR EMG')
subtitle('Trial Max and Min vs 100-200ms Max and Min')
xlabel('Time (ms)');
ylabel('EMG (mV)');
legend('Trial Maximum','Trial Minimum', '100-200ms Maximum', '100-200ms Minimum', 'location', 'northeastoutside', 'box','off')
ax11 = gca;
ax11.FontSize = 18;
ylim([-1.3 1.3])
grid off;
box off
hold off;

%% Bunch of plots

trialnum = 1:1:10;
trialnum= cellstr(num2str(trialnum'));
mean_timevec_100 = 100:100:1500;
mean_timevec_50 = 50:50:1500;

max_mean50win = max(max(Means.win50ms.flex))+0.02;
max_var50win = max(max(Vars.win50ms.flex))+0.02;
max_std50win = max(max(STD.win50ms.flex))+0.02;

min_mean50win = min(min(Means.win50ms.flex))-0.02;
min_var50win = min(min(Vars.win50ms.flex))-0.02;
min_std50win = min(min(STD.win50ms.flex))-0.02;

% Only need max min of trial and max min of trial at 100-200ms
% figure;
% for nTrial= 1:numTrials
%     plot(mean_timevec_100,Max.win100ms.flex(nTrial,:));
%     hold on
%     plot(mean_timevec_100,Min.win100ms.flex(nTrial,:));
% end
% title('FCR EMG - Max and Min -- 100ms Windowed')
% subtitle('Full Trial')
% ax3 = gca;
% ax3.FontSize = 18;
% xlabel('Time (ms)')
% ylabel('EMG (mV)')
% leg = legend(trialnum, 'box', 'off', 'location', 'northeastoutside');
% title(leg, 'Trial Number');
% box off

figure;
plot(abs_flex(nTrial,:), LineWidth=1);

title('Absolute Value EMG')
ax4 = gca;
ax4.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('FCR EMG', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'Trial 1');
box off

figure;
for nTrial= 1:numTrials
    plot(mean_timevec_50,Means.win50ms.flex(nTrial,:));
    hold on
    % plot(Means.win50ms.ext(nTrial,:));
end
title('Matlab Mean -- 50ms Windowed')
ax5 = gca;
ax5.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend(trialnum, 'box', 'off', 'location', 'northeastoutside');
title(leg, 'Trial Number');
ylim([min_mean50win max_mean50win])
box off

figure;
plot(Means_my.win50ms.flex(1,:),'b',linewidth=1);
title('Trial 1 - Matlab Mean -- 50ms Windowed')
ax6 = gca;
ax6.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('Matlab Mean', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'FCR EMG');

ylim([min_mean50win max_mean50win])

figure;
plot(Means_my.win50ms.flex(1,:),'r',linewidth=1);
title('Trial 1 - My Calculated Mean -- 50ms Windowed')
ax6 = gca;
ax6.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('My Mean Calculation', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'FCR EMG');

ylim([min_mean50win max_mean50win])
box off

figure;
plot(Vars.win50ms.flex(1,:),linewidth=1);
hold on
plot(Vars_my.win50ms.flex(1,:),linewidth=1);

title('Variance -- 50ms Windowed')
subtitle('(Mean Background EMG Subtracted)')
ax90 = gca;
ax90.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('Matlab Variance','My Variance Calculation', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'FCR EMG');

figure;
plot(STD.win50ms.flex(1,:),linewidth=1);
hold on
plot(STD_my.win50ms.flex(1,:),linewidth=1);

title('STD -- 50ms Windowed')
subtitle('(Mean Background EMG Subtracted)')
ax90 = gca;
ax90.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('Matlab STD','My STD Calculation', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'FCR EMG');

figure;
plot(RMS.win50ms.flex(1,:),'b',linewidth=1);

title('Matlab RMS -- 50ms Windowed')
subtitle('(Mean Background EMG Subtracted)')
ax90 = gca;
ax90.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('Matlab RMS', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'FCR EMG');

figure
plot(RMS_my.win50ms.flex(1,:),'r',linewidth=1);

title('My RMS Calculation -- 50ms Windowed')
subtitle('(Mean Background EMG Subtracted)')
ax90 = gca;
ax90.FontSize = 18;
xlabel('Time (ms)')
ylabel('EMG (mV)')
leg = legend('My RMS Calculation', 'box', 'off', 'location', 'northeastoutside');
title(leg, 'FCR EMG');
           
