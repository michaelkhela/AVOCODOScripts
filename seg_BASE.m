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

    %================= added by Winko An 02/10/2025 =======================
    rej = [start_latency,end_latency];%start and end of segment (ms)
    EEG = eeg_eegrej(EEG,rej);
    %======================================================================
    
    fprintf('Segment found. Processing only this segment.\n');
else
    fprintf('No segmentation markers found. Processing the entire dataset.\n');
end

% Remove segmentation markers
EEG.event(strcmp({EEG.event.type}, 'seg_str')) = [];
EEG.event(strcmp({EEG.event.type}, 'seg_end')) = [];