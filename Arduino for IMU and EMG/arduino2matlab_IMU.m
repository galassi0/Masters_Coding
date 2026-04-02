% Author: Matt Galassi
% Created: October 1st, 2025
% Last edited: Oct 11th, 2025
%
% Open Serial port to read and record acceleration and gyro from MPU6050
% and record the square wave sync pulse.
%
% Pin_State is the sync pulse.

%%

%--- Configuration ---
COMPORT = 'COM5';         % <<< VERIFY THIS PORT!
BAUD_RATE = 115200;
FILENAME = 'combined_log.csv';

% ... (Setup Serial Port code remains the same: 
s = serialport(COMPORT, BAUD_RATE);

% --- Setup File Logging ---
fileID = fopen(FILENAME, 'w');
if fileID == -1
    error('Cannot open file for writing: %s', FILENAME);
end
disp(['Logging data to: ' FILENAME]);

% Write the NEW header to the file
% The header MUST match the order of data sent by the Arduino!
fprintf(fileID, 'Time_micros,Pin_State,Accel_X,Accel_Y,Accel_Z,Gyro_X,Gyro_Y,Gyro_Z\n');

% --- Data Acquisition Loop ---
try
    % ... (Flush and Pause code remains the same) ...
    
    while true
        dataLine = readline(s);
        
        if ~isempty(dataLine)
            disp(dataLine); 
            
            % PROCESS: Replace the separator ' | ' with a comma for CSV format
            processedLine = strrep(dataLine, ' | ', ',');
            
            % Write the processed line to the file
            fprintf(fileID, '%s\n', processedLine);
        end
        
        pause(0.001); 
    end

catch ME
    % --- Cleanup (Crucial for saving) ---
    warning('Logging stopped due to error or user interruption (Ctrl+C).');
    disp(['Error Message: ' ME.message]);
    fclose(fileID);
    disp('File closed.');
    delete(s);
    clear s;
    disp('Serial port closed and cleared.');
end
