# EEG Preprocessing & Segmentation Scripts  

## Overview  
This repository contains MATLAB scripts for preprocessing and segmenting EEG event data. These scripts streamline the analysis of several different paradigms and structured event data by ensuring event integrity and proper segmentation. Made to be used with Avocodo (https://github.com/winkoan/AVOCODO).

## Scripts  

### `habanero.m`  
- Identifies EEG segment markers (`seg_str` and `seg_end`).  
- Retains only the intended segment of data for analysis.  
- Ensures accurate event extraction within the segmented portion. 
- Standardizes EEG event markers.  
- Processes and formats event data.  
- Exports structured output for analysis.  

### `seg_base.m`  
- Identifies EEG segment markers (`seg_str` and `seg_end`).  
- Retains only the intended segment of data for analysis.  
- Ensures accurate event extraction within the segmented portion.  

### `pico_de_chirp.m`  
- Identifies EEG segment markers (`seg_str` and `seg_end`).  
- Retains only the intended segment of data for analysis.  
- Ensures accurate event extraction within the segmented portion. 
- Standardizes EEG event markers.  
- Processes and formats event data.  
- Exports structured output for analysis. 

## Usage  
1. Ensure your MATLAB environment is set up for AVOCODD.  
2. Load your EEG data.  
3. Run the relevant script (`habanero.m`, `seg_base.m`, or `pico_de_chirp.m`).  
4. Processed EEG events will be exported in a structured format for further analysis.  

## Contributions  
Feel free to submit pull requests or report issues to improve functionality.  

## License  
This project is licensed under [MIT License](LICENSE).  

