clc,clear
% Define the serial port (make sure to change this to match your system's port)
serialPort = 'COM4';  % Example port, update based on your system

% Open the serial connection (if using a newer version of MATLAB, use serialport)
s = serial(serialPort, 'BaudRate', 115200, 'Terminator', 'LF', 'Timeout', 10);

% Open the serial port for communication
fopen(s);

% Create a file to save the EMG data
outputFile = ['emg_data.mat'];  % You can change the filename as needed

% Number of samples you want to collect
numSamples = 10000;  % Change this to collect more or fewer samples

% Pre-allocate an array to store the data
data = zeros(numSamples, 2);  % Column 1 for timestamp, column 2 for EMG reading

% Read data from the Arduino
for i = 1:numSamples
    % Read one line of data from the serial port
    line = fgetl(s);  % Read the line as a string
    
    % Split the line into timestamp and EMG reading (assuming it's comma separated)
    dataParts = str2double(strsplit(line, ','));
    
    % Store the timestamp and EMG reading in the pre-allocated array
    data(i, 1) = dataParts(1);  % Timestamp
    data(i, 2) = dataParts(2);  % EMG reading
    
    % Optionally, display data in real-time (can slow down the sampling rate)
    disp(data(i, :));
end

% Save the collected data to a .mat file
save(outputFile, 'data');

% Close the serial connection
fclose(s);
delete(s);
clear s;

disp('EMG data collection complete and saved to output file');