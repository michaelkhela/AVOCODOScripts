% This script processes EEG events for habituation paradigms. 
% It removes specific sequences of events, renames events based on their type, 
% and drops any event that isn't 'din' (listed below), a habituation marker.
% It also exports all events to three CSV files: Initial before removing tags,
% a collection of matlab tags, and a post-processing event list
% Created by Michael Khela (ch242188)

% Name tags that you want to keep
din_markers = {'TRSP', 'bgin', 'stm+'};

% First pass: Remove non-target events
for idx = length(EEG.event):-1:1  % Iterate backwards to safely remove elements
    event_type = EEG.event(idx).type;
    
    % Remove any event that isn't a 'din'
    if ~any(strcmp(event_type, din_markers))
        EEG.event(idx) = [];  % Remove the event
    end
end


% Second pass: Creating the inital events BEFORE ANY EDITING
% ============ EEG file name; added by Winko ===============
file_name = app.list_eeg_files.Value; % Get the file name from the app
% ==========================================================

% Extract the ID from the file name (assuming it's the first part before the underscore)
[~, name, ~] = fileparts(file_name); % Get the file name without extension
id_parts = split(name, '_'); % Split the file name by underscores
id = strjoin(id_parts(1:2), '_'); % Combine the first two parts (ID and visit number)

% After the first pass: Export initial events in .ns.csv format
initial_event_data = struct2table(EEG.event); % Convert the EEG.event structure to a table

% Define output path and file name with ID included
out_path = 'data/2_csv_events'; 
if ~exist(out_path, 'dir')
    mkdir(out_path);
end

% Define the format of the begintime
format_in = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSXXX'; % Include timezone offset

% Convert latency from ms to seconds for the initial events
initial_event_data.latency = initial_event_data.latency / 1000;

% Define the format of the begintime
initial_event_data.begintime = datetime(initial_event_data.begintime, 'InputFormat', format_in, 'TimeZone', 'UTC');
initial_event_data.begintime.TimeZone = '';  % Remove timezone for export
initial_event_data.begintime.Format = 'ddMMyyyy/HH:mm:ss.SSSSSS';  % Set the output format

% Define output path and file name for the initial events
initial_out_file = fullfile(out_path, sprintf('%s_VEP_initial_events.csv', id));

% Check if required columns exist before filtering
if all(ismember({'begintime', 'code', 'latency', 'mffkeys'}, initial_event_data.Properties.VariableNames))
    filtered_initial_data = initial_event_data(:, {'code','begintime','latency', 'mffkeys'});
else
    error('One or more specified columns are missing in the initial event data.');
end

% Rename columns to match the .ns format
filtered_initial_data.Properties.VariableNames = {'Code','Onset','Latency','Trial'};

% Add Trial Numbering Logic
current_trial = 1; % Start with trial 1

% Loop over rows and assign trial numbers
for i = 1:height(filtered_initial_data)
    row = filtered_initial_data.Code{i}; % Get the current event code

    % Assign the current trial number to all events until 'TRSP'
    filtered_initial_data.Trial{i} = num2str(current_trial);

    % If the event is 'TRSP', increment the trial number after assigning
    if strcmp(row, 'TRSP')
        current_trial = current_trial + 1; % Increment the trial for the next set
    end
end

% Update the 'Trial' column with the correct trial number values
filtered_initial_data.('Trial') = filtered_initial_data.Trial;  % This line is now included

% Open the initial output CSV file for writing
fid_initial = fopen(initial_out_file, 'w');

% Write the two rows of metadata (filename and description)
fprintf(fid_initial, 'Filename:,%s\n', file_name);  % First row with filename
fprintf(fid_initial, 'Description:,%s\n', 'Initial events after dropping of other tags'); % Second row with description

% Write the table headers manually
fprintf(fid_initial, 'Code,Onset,Latency,Trial\n');

% Close the file to ensure manual writes are saved
fclose(fid_initial);

% Append the filtered initial event data to the CSV
writetable(filtered_initial_data, initial_out_file, 'WriteMode', 'append');

% Notify user of completion
fprintf('\n\nInitial events after first pass saved! \n');



% Third Pass: Takes out the good/bad trials and created final data set
% Load good/bad trial data
good_bad_csv = '/Users/michaelkhela/Desktop/vep/LabelledGoodBadTrials_12034.csv'; % Path to the good/bad CSV
good_bad_data = readtable(good_bad_csv);

% Create a cell array for bad trials (assuming TrialID is numeric)
bad_trials = string(good_bad_data.TrialID(strcmp(good_bad_data.label, 'BAD'))); % Convert to string for comparison

% Initialize a new array for trial numbers
trial_numbers = cell(length(EEG.event), 1);  % Create a cell array to hold trial numbers
current_trial = 1; % Start with trial 1

% Loop over events and assign trial numbers
for i = 1:length(EEG.event)
    event_code = EEG.event(i).type; % Get the current event code

    % Assign the current trial number to all events until 'TRSP'
    trial_numbers{i} = num2str(current_trial);

    % If the event is 'TRSP', increment the trial number after assigning
    if strcmp(event_code, 'TRSP')
        current_trial = current_trial + 1; % Increment the trial for the next set
    end
end

% Add the trial numbers to the EEG.event structure
for i = 1:length(EEG.event)
    EEG.event(i).trial_number = trial_numbers{i};  % Store the trial number in each event
end

% Filter out bad trials
good_mask = ~ismember(string({EEG.event.trial_number}), bad_trials); % Create a mask for good trials
EEG.event = EEG.event(good_mask); % Keep only good trials


% Fourth Pass: Converts to CSV for Matlab and Final
% Convert the EEG.event structure to a table
event_data = struct2table(EEG.event);

% Perform any necessary checks on the EEG structure
EEG = eeg_checkset(EEG);

% Convert latency from ms to seconds
event_data.latency = event_data.latency / 1000;

% Convert 'begintime' to datetime with the specified format
try
    % Specify the time zone for conversion (e.g., 'UTC')
    event_data.begintime = datetime(event_data.begintime, 'InputFormat', format_in, 'TimeZone', 'UTC');
    % Convert to unzoned datetime
    event_data.begintime.TimeZone = ''; 
catch ME
    disp('Error converting begintime. Please check the format of begintime.');
    disp(ME.message); % Display the error message
    rethrow(ME);
end

% Modify the format for output
event_data.begintime.Format = 'ddMMyyyy/HH:mm:ss.SSSSSS';

% Define output file for Matlab events
out_file = fullfile(out_path, sprintf('%s_VEP_matlab_events.csv', id));

% Write the event data table to a CSV file
writetable(event_data, out_file);

% Notify user of completion
fprintf('\n\nMatlab Specific EEG events saved!\n');

% Define input and output paths for filtered data
input_csv = fullfile(out_path, sprintf('%s_VEP_matlab_events.csv', id)); % Path to the existing CSV file
output_csv = fullfile(out_path, sprintf('%s_VEP_final_events.csv', id)); % Path for the new CSV file

% Read the existing CSV file
data = readtable(input_csv);

% Extract the relevant columns
if all(ismember({'begintime', 'code', 'latency', 'trial_number'}, data.Properties.VariableNames))
    filtered_data = data(:, {'code','begintime','latency', 'trial_number'});
else
    error('One or more specified columns are missing in the input CSV file.');
end

% Rename columns to match the desired headers
filtered_data.Properties.VariableNames = {'Code','Onset','Latency','Trial'};

% Open the output CSV file for writing
fid = fopen(output_csv, 'w');

% Write the two rows of metadata (filename and description)
fprintf(fid, 'Filename:,%s\n', file_name);  % First row with filename

% Write the table headers manually
fprintf(fid, 'Code,Onset,Latency,Trial\n');

% Close the file to ensure the manual writes are saved
fclose(fid);

% Write the updated table to the output CSV
writetable(filtered_data, output_csv, 'WriteMode', 'append');

% Notify user of completion
fprintf('\n\nFiltered data is saved!\n');