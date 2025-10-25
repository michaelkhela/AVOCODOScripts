clear all
warning off
clc
% This script loads in mff files exported by avocodo
% and change code information and resave

%% Toolbox
if ispc
    addpath(genpath('/Users/michaelkhela/Desktop/AVOCODO/eeglab'),'-end');
else
    addpath(genpath('/Users/michaelkhela/Desktop/AVOCODO/eeglab'),'-end');
    fprintf('\n\EEGLAB Failed!\n')
end

%% Paths
if ispc
    dir_in = fullfile('/Users/michaelkhela/Library/CloudStorage/GoogleDrive-michael.khela@enders.tch.harvard.edu/Shared drives/W-FRAXA/02_data_and_projects/data_EEG/2_Habituation/1.2_marked_EEG/0_original_mff');
    dir_out = fullfile('/Users/michaelkhela/Library/CloudStorage/GoogleDrive-michael.khela@enders.tch.harvard.edu/Shared drives/W-FRAXA/02_data_and_projects/data_EEG/2_Habituation/1.2_marked_EEG/1_edited_mff');
else
    dir_in = fullfile('/Users/michaelkhela/Library/CloudStorage/GoogleDrive-michael.khela@enders.tch.harvard.edu/Shared drives/W-FRAXA/02_data_and_projects/data_EEG/2_Habituation/1.2_marked_EEG/0_original_mff');
    dir_out = fullfile('/Users/michaelkhela/Library/CloudStorage/GoogleDrive-michael.khela@enders.tch.harvard.edu/Shared drives/W-FRAXA/02_data_and_projects/data_EEG/2_Habituation/1.2_marked_EEG/1_edited_mff');
    fprintf('\n\Path Failed!\n')
end

%% Parameters
code_original = {'DI10','DI20','DI30'};
code_new = {'Firt','Secd','Thid'};

%% Main
files_all = dir(fullfile(dir_in,'*.mff'));
for idx_file = 1:length(files_all)
   file = fullfile(dir_in,files_all(idx_file).name); 
   
   % Load EEG
   EEG = pop_mffimport(file , [], 0, 0) ;
   
   % Corrected event code
   for idx_event = 1:length(EEG.event)
       for idx_code = 1:length(code_original)
           if strcmp(EEG.event(idx_event).code,code_original{idx_code})
               EEG.event(idx_event).code = code_new{idx_code};
           end
       end      
   end
   
   % Save EEG
   pop_mffexport( EEG, fullfile(dir_out,files_all(idx_file).name));
end
