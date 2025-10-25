% This script processes EEG events for the chirp paradigms. 
% It removes specific sequences of events, renames events based on their type, 
% and drops any event that isn't 'din' (listed below), a chirp marker, or 'vbeg'.
% It also exports all events to three CSV files: Initial before removing tags,
% a collection of MATLAB tags, and a post-processing event list.
% Additionally, will segement the data if the data needs to be segemented.
% Created by Michael Khela (ch242188)

% === Check for 'seg_str' and 'seg_end' ===
seg_start = 'seg_str';
seg_end = 'seg_end';

start_idx = find(strcmp({EEG.event.type}, seg_start), 1);
end_idx = find(strcmp({EEG.event.type}, seg_end), 1, 'last');

if ~isempty(start_idx) && ~isempty(end_idx)
    start_latency = EEG.event(start_idx).latency;
    end_latency = EEG.event(end_idx).latency; 
    
    % keep only that segment
    EEG = pop_select(EEG, 'point', [start_latency end_latency]);
    
    fprintf('Segment found. Kept samples %d to %d only.\n', start_latency, end_latency);
else
    fprintf('No segmentation markers found. Processing the entire dataset.\n');
end

% === Continue with the rest of the code ===

% Define the markers indicating chirp events
chirp_markers = {'pbeh', 'nonp', 'pcry', 'pvoc'}; 

% Define the markers indicating din events
din_markers = {'DI11', 'DI22'};

% First pass: Rename events and remove non-target events
for idx = length(EEG.event):-1:1  % Iterate backwards to safely remove elements
    event_type = EEG.event(idx).type;
    
    % Rename events based on their current type
    if strcmp(event_type, 'DI11')
        EEG.event(idx).type = 'Start';
    elseif strcmp(event_type, 'DI22')
        EEG.event(idx).type = 'Stop';
    elseif ~any(strcmp(event_type, [chirp_markers, din_markers]))
        % Remove any event that isn't a 'din' or a chirp marker
        EEG.event(idx) = [];  % Remove the event
    end
end

% 1.5 pass: Create the initial event tags before removal of the chirp markers in the second pass
file_name = app.list_eeg_files.Value; % Get the file name from the app

% Extract the ID from the file name
[~, name, ~] = fileparts(file_name);
id_parts = split(name, '_');
id = strjoin(id_parts(1:2), '_');

% Export initial events in .ns.csv format
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
initial_out_file = fullfile(out_path, sprintf('%s_chirp_initial_events.csv', id));

% Check if required columns exist before filtering
if all(ismember({'begintime', 'code', 'latency', 'type'}, initial_event_data.Properties.VariableNames))
    filtered_initial_data = initial_event_data(:, {'type','code','begintime','latency'});
else
    error('One or more specified columns are missing in the initial event data.');
end

% Rename columns to match the .ns format
filtered_initial_data.Properties.VariableNames = {'Code','Label','Onset','Latency'};

% Open the initial output CSV file for writing
fid_initial = fopen(initial_out_file, 'w');

% Write the two rows of metadata (filename and description)
fprintf(fid_initial, 'Filename:,%s\n', file_name);  % First row with filename
fprintf(fid_initial, 'Description:,%s\n', 'Initial events after first pass'); % Second row with description

% Write the table headers manually
fprintf(fid_initial, 'Code,Label,Onset,Latency\n');

% Close the file to ensure manual writes are saved
fclose(fid_initial);

% Append the filtered initial event data to the CSV
writetable(filtered_initial_data, initial_out_file, 'WriteMode', 'append');

% Notify user of completion
fprintf('\n\nInitial events after first pass saved! \n');

% Second pass: Mark events for removal based on the most complete sequence
for idx = 1:length(EEG.event)  % Check ALL events
    fprintf('Checking event %d: %s\n', idx, EEG.event(idx).type);
    
    if idx > 1 && idx < length(EEG.event) % Check if we are within valid bounds for neighbors
        if strcmp(EEG.event(idx-1).type, 'Start') && ...
           any(strcmp(EEG.event(idx).type, chirp_markers)) && ...
           strcmp(EEG.event(idx+1).type, 'Stop')
            % Mark all events in this sequence for removal
            EEG.event(idx-1).type = 'removed';
            EEG.event(idx).type = 'removed';
            EEG.event(idx+1).type = 'removed';
        end
    end
end

% Count and log events marked for removal
num_removed = sum(strcmp({EEG.event.type}, 'removed'));
fprintf('Number of events marked for removal after second pass: %d\n', num_removed);

% Third pass: Mark remaining events for less complete sequences
for idx = 1:length(EEG.event)  % Check ALL events
    fprintf('Checking event %d: %s\n', idx, EEG.event(idx).type);
    
    if idx > 1  % Ensure we are within bounds for the first comparison
        if strcmp(EEG.event(idx-1).type, 'Start') && ...
           any(strcmp(EEG.event(idx).type, chirp_markers))
            % Mark these events for removal
            EEG.event(idx-1).type = 'removed';
            EEG.event(idx).type = 'removed';
        end
    end
end

% Count and log remaining events marked for removal
num_removed = sum(strcmp({EEG.event.type}, 'removed'));
fprintf('Number of events marked for removal after third pass: %d\n', num_removed);

% Final cleanup: Remove all 'removed' events
EEG.event(strcmp({EEG.event.type}, 'removed')) = [];

% Convert the EEG.event structure to a table
event_data = struct2table(EEG.event);

% Perform any necessary checks on the EEG structure
EEG = eeg_checkset(EEG);

% Convert latency from ms to seconds
event_data.latency = event_data.latency / 1000;

% Convert 'begintime' to datetime with the specified format
try
    event_data.begintime = datetime(event_data.begintime, 'InputFormat', format_in, 'TimeZone', 'UTC');
    event_data.begintime.TimeZone = ''; 
catch ME
    disp('Error converting begintime. Please check the format of begintime.');
    disp(ME.message); % Display the error message
    rethrow(ME);
end

% Modify the format for output
event_data.begintime.Format = 'ddMMyyyy/HH:mm:ss.SSSSSS';

% Define output file
out_file = fullfile(out_path, sprintf('%s_chirp_matlab_events.csv', id));

% Write the event data table to a CSV file
writetable(event_data, out_file);

% Notify user of completion
fprintf('\n\nMatlab Specific EEG events saved!\n');

% Define input and output paths for filtered data
input_csv = fullfile(out_path, sprintf('%s_chirp_matlab_events.csv', id)); % Path to the existing CSV file
output_csv = fullfile(out_path, sprintf('%s_chirp_final_events.csv', id)); % Path for the new CSV file

% Read the existing CSV file
data = readtable(input_csv);

% Extract the relevant columns
if all(ismember({'begintime', 'code', 'latency', 'type'}, data.Properties.VariableNames))
    filtered_data = data(:, {'type','code','begintime','latency'});
else
    error('One or more specified columns are missing in the input CSV file.');
end

% Rename columns to match the desired headers
filtered_data.Properties.VariableNames = {'Code','Label','Onset','Latency'};

% Open the output CSV file for writing
fid = fopen(output_csv, 'w');

% Write the two rows of metadata (filename and description)
fprintf(fid, 'Filename:,%s\n', file_name);  % First row with filename
fprintf(fid, 'Description:,%s\n', 'This is the final that can be compared with ns and ready for processing'); % Second row with a custom description

% Write the table headers manually
fprintf(fid, 'Code,Label,Onset,Latency\n');

% Close the file to ensure the manual writes are saved
fclose(fid);

% Append the filtered data to the CSV
writetable(filtered_data, output_csv, 'WriteMode', 'append');

% Notify user of completion
fprintf('\n\nFiltered data saved!\n');
