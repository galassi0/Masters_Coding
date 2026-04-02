% Author: Matt Galassi
% Date: July 11th, 2025
% Last Edited: August 15th, 2025 -- in progress
%
% Takes in the multisine vestibular stimulation signal, and calculates d'
% for the various component frequencies. Plots input signal with output Fx 
% of a forceplate.
%

%% Process and Filter the Data
clear,clc
% Line 300, check!!

d= readmatrix("GVSMultiSineEO1.csv");
% d2 = readmatrix("GVSMultiSineEOVm30.csv");
% ss = readmatrix("GVSSineEO.csv");

Fx = d(:,29);
Fy = d(:,30);
Fz = d(:,31);
Mx = d(:,32);
My = d(:,33);
Mz = d(:,34);
GVS = d(:,60)';
Fs = 500;

% CoP for ML and AP
CoPml = LowPassFilter(-1*(My./Fz),500,2,10);
CoPap = LowPassFilter(Mx./Fz,500,2,10);

% Correcting Offsets in GVS and Fx
offset_GVS = mean(GVS);
GVS_corrected = GVS-offset_GVS;

offset_Fx = mean(Fx);                       % Change all variables to "output" rather than Fx or My, then at top specify, output = My
Fx_corrected = Fx-offset_Fx;                % <---- Here too

% Filtering the GVS input (filtfilt butter with 10Hz cutoff)
norm_cutoff = 10/(Fs/2);
[b, a] = butter(4,norm_cutoff,'low');
segment = filtfilt(b, a, GVS_corrected');



% % Filtering Output Force cutoff 10Hz
% norm_cutoff = 10/(Fs/2);
% [b, a] = butter(4,norm_cutoff,'low');
% Fx_filt = filtfilt(b, a, Fx_corrected);
Fx_filt = Fx_corrected;

% Amin's Input 
t = 1/500:1/500:60;
signalMultiGVS = 0.2 * (sin(2*pi*0.3*t) + sin(2*pi*0.5*t) + sin(2*pi*0.7*t) + sin(2*pi*1.1*t));

% switching from voltage input to raw sine input
% signal_segment = segment(4196:19195);
signal_segment = signalMultiGVS(1:15000);
L = numel(signal_segment);

% Gaussian Filter 2 - Success
% Parameters
N = numel(Fx_filt(4196:19195));          % Number of data points
% Center frequency of the Gaussian filter (Hz)
fwhm = 0.1;         % Full width at half maximum (Hz)
sigma = fwhm / (2 * sqrt(2 * log(2))); % Standard deviation in frequency domain

% FFT
Fx_fft = fft(Fx_filt(4196:19195));

% Frequency axis
df = Fs / N;                        % Frequency resolution
f = (0:N-1) * df;                   % Full frequency axis (0 to fs)
f2 = f - Fs * (f >= Fs/2);           % Shift to [-fs/2, fs/2) for centered spectrum
mu = [0.3, 0.5, 0.7, 1.1];
fieldname = {"f_03hz", "f_05hz", "f_07hz", "f_11hz"};

for i = 1:4
    % Create Gaussian filter centered at f0
    gaussian_filter = exp(-((f2 - mu(i)).^2) / (2 * sigma^2))';
    
    % Mirror the filter for negative frequencies
    f_neg = -1*(mu(i)); % Corresponding negative frequency
    gaussian_filter_neg = exp(-((f2 - f_neg).^2) / (2 * sigma^2))';
    gaussian_filter = gaussian_filter + gaussian_filter_neg; % Combine positive and negative frequency filters
    
    % Normalize the filter to preserve energy
    gaussian_filter = gaussian_filter / max(gaussian_filter);
    
    % Apply the filter in the frequency domain
    X_filtered.(fieldname{i}) = Fx_fft .* gaussian_filter;

    % Inverse FFT to get filtered time-domain signal
    filtered_data.(fieldname{i}) = ifft(X_filtered.(fieldname{i}), 'symmetric'); % 'symmetric' ensures real output
end

% ZeroFilt input for correlation:

[input,~] = zeroFilt(signal_segment,500,[0.3,0.5,0.7,1.1], 30, "no");
input_aligned = {};

% Cross Correlation:

two_sec_limit = Fs*2;
input_aligned = {1:numel(input)};

for i = 1:4
    
    [corr, lags] = xcorr(input{i},filtered_data.(fieldname{i}));
    % only positives -- and capping the response to be within 2 seconds of
    % the input (doesnt make much sense for the body to respond at 11s
    % (0.3Hz response lag)).
    valid_lags = (two_sec_limit > lags) & (lags >= 0);                      
    pos_corr = corr(valid_lags);
    pos_lags = lags(valid_lags);
    [maxcorr,maxidx] = max(abs(pos_corr));
    optimal_lag.(fieldname{i}) = pos_lags(maxidx);

    startIDX = optimal_lag.(fieldname{i}) + 1;
    endIDX = N;
    filtered_data_aligned.(fieldname{i}) = filtered_data.(fieldname{i})(1:endIDX-optimal_lag.(fieldname{i}));
    input_aligned{i} = input{i}(startIDX:endIDX);
    
    % [corr, lags] = xcorr(input{i},filtered_data.(fieldname{i}));
    % [maxcorr,maxidx] = max(abs(corr));
    % optimal_lag = lags(maxidx);
    % 
    % if optimal_lag >= 0
    %     % positive shift
    %     startIDX = optimal_lag + 1;
    %     endIDX = N;
    %     filtered_data_aligned.(fieldname{i}) = filtered_data.(fieldname{i})(1:endIDX-optimal_lag);
    %     input_aligned{i} = input{i}(startIDX:endIDX);
    % else
    %     % negative shift
    %     startIDX = -optimal_lag + 1;
    %     input_aligned{i} = input{i}(1:endIDX+optimal_lag); %startIDX would be negative, so times by -1, and adding it
    %     filtered_data_aligned.(fieldname{i}) = filtered_data.(fieldname{i})(startIDX:endIDX);
    % end
end

for i = 1:4
    lag_sec.(fieldname{i}) = optimal_lag.(fieldname{i})/500;
end

% Background data and d'

% Frequency axis
df = Fs / N;                        % Frequency resolution
f = (0:N-1) * df;                   % Full frequency axis (0 to fs)
f2 = f - Fs * (f >= Fs/2);           % Shift to [-fs/2, fs/2) for centered spectrum
mu = [0.3, 0.5, 0.7, 1.1];
fieldname = {"f_03hz", "f_05hz", "f_07hz", "f_11hz"};
fieldname_binIDX = {"bin_03", "bin_05", "bin_07", "bin_11"};
fname_groupM = {"f_03hz_groupM", "f_05hz_groupM", "f_07hz_groupM", "f_11hz_groupM"};
fname_groupV = {"f_03hz_groupV", "f_05hz_groupV", "f_07hz_groupV", "f_11hz_groupV"};


for i = 1:4
    
    % Boundaries for bins
    steppoint = 0.025;

    % need to round as some floating point errors create mean issues
    last_edge = round(max(input_aligned{i}),2);
    % last_edge = ceil(last_edge*10) / 10;
    first_edge = round(min(input_aligned{i}),2);
    % first_edge = floor(first_edge*10)/10;
   

    bin_vector{i} = (first_edge:steppoint:last_edge)';
    bin_edges{i} = (first_edge-0.0125:steppoint:last_edge+0.0125)';
    
   
    filtered_data_aligned.(fieldname_binIDX{i}) = discretize(input_aligned{i}, bin_edges{i})';
    filtered_data_aligned.(fname_groupM{i}) = accumarray(filtered_data_aligned.(fieldname_binIDX{i}),filtered_data_aligned.(fieldname{i}),[numel(bin_vector{i}), 1],@mean);
    filtered_data_aligned.(fname_groupV{i}) = accumarray(filtered_data_aligned.(fieldname_binIDX{i}),filtered_data_aligned.(fieldname{i}),[numel(bin_vector{i}), 1],@var);
   
end

fgroup_d = {"f_03hz_dp", "f_05hz_dp", "f_07hz_dp", "f_11hz_dp"};
for i = 1:4
    for j = 1:numel(filtered_data_aligned.(fname_groupM{i}))
        mu_MVS_on = filtered_data_aligned.(fname_groupM{i})(j);
        binv_off_idx = find(bin_vector{i} == 0);
        mu_MVS_off = filtered_data_aligned.(fname_groupM{i})(binv_off_idx);
        %mu_MVS_off = filtered_data_bkgd.(fname_groupM{i})(j);
        var_MVS_on = filtered_data_aligned.(fname_groupV{i})(j);
        var_MVS_off = filtered_data_aligned.(fname_groupV{i})(binv_off_idx);
        filtered_data_aligned.(fgroup_d{i})(j) = (abs(mu_MVS_on - mu_MVS_off) / sqrt((var_MVS_on + var_MVS_off) / 2));
    end

end


%% Plot 
figure;
subplot(4,3,1); plot(input_aligned{1},filtered_data_aligned.f_03hz) 
title("0.3Hz")
xlim([min(bin_edges{2}), max(bin_edges{2})])
subplot(4,3,2); plot(filtered_data_aligned.f_03hz);
hold on
yyaxis right
plot(input_aligned{1})
title(lag_sec.(fieldname{1})+ " sec lag of output")
legend("Output","Input")
hold off
subplot(4,3,3); plot(bin_vector{1},filtered_data_aligned.f_03hz_dp)
hold on
plot(bin_vector{1},filtered_data_aligned.f_03hz_dp, 'o');

subplot(4,3,4); plot(input_aligned{2},filtered_data_aligned.f_05hz)
title("0.5Hz")
xlim([min(bin_edges{2}), max(bin_edges{2})])
subplot(4,3,5); plot(filtered_data_aligned.f_05hz)
hold on
yyaxis right
plot(input_aligned{2})
title(lag_sec.(fieldname{2})+ " sec lag of output")
hold off
subplot(4,3,6); plot(bin_vector{2},filtered_data_aligned.f_05hz_dp)
hold on
plot(bin_vector{1},filtered_data_aligned.f_05hz_dp, 'o');


subplot(4,3,7); plot(input_aligned{3},filtered_data_aligned.f_07hz)
title("0.7Hz")
xlim([min(bin_edges{2}), max(bin_edges{2})])
subplot(4,3,8); plot(filtered_data_aligned.f_07hz)
hold on
yyaxis right
plot(input_aligned{3})
title(lag_sec.(fieldname{3})+ " sec lag of output")
hold off
subplot(4,3,9); plot(bin_vector{3},filtered_data_aligned.f_07hz_dp)
hold on
plot(bin_vector{1},filtered_data_aligned.f_07hz_dp, 'o');

subplot(4,3,10); plot(input_aligned{4},filtered_data_aligned.f_11hz)
title("1.1Hz")
xlim([min(bin_edges{2}), max(bin_edges{2})])

subplot(4,3,11); plot(filtered_data_aligned.f_11hz)
hold on
yyaxis right
plot(input_aligned{4})
title(lag_sec.(fieldname{4})+ " sec lag of output")
hold off
subplot(4,3,12); plot(bin_vector{4},filtered_data_aligned.f_11hz_dp)
hold on
plot(bin_vector{1},filtered_data_aligned.f_11hz_dp, 'o');

%% Testing phase delay and the saw tooth pattern

input_sig = input{2};
output_sig = filtered_data.f_05hz;
[Pxy, F_phase] = cpsd(input_sig, output_sig, [], [], [], Fs);

phase_deg = rad2deg(angle(Pxy));

% Plot the phase vs frequency
figure;
plot(F_phase, phase_deg);
title('Phase Difference Between Input and Output');
xlabel('Frequency (Hz)');
ylabel('Phase Difference (Degrees)');
grid on;

