# iEEG

Functions to analyse intracranial electroencephalography (iEEG) data, based on fieldtrip. 

Try this order:


1. Import_Neuralynx.m --> Imports data from Neuralynx

2. Correct_Neuralynx_Triggers.m --> Corrects for additional triggers that may appear on Neuralynx (optional step)

3. Preprocess_combineelectrodes.m --> Combines iEEG files from all stripes and formats them for fieldtrip

4. extract_singletrials.m --> Splits iEEG data to experimental conditions and computes some basic pre-processing

5. Stats_TimeLocked.m --> Statistical contrast for two experimental conditions in the time domain.

Use at your own risk!
