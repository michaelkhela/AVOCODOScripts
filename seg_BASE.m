% This script processes EEG events for the baseline paradigm. 
% If segment markers ('seg_str' and 'seg_end') are found, the script will 
% segment the EEG data to include only the portion between these markers. 
% If segmentation is not required, the entire dataset is processed as usual.
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
