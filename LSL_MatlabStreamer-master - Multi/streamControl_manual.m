function streamControl_manual(datasetName,datasetName2, rawDataPath, oneChannel)
% streamControl_nogui(datasetName, rawDataPath, oneChannel)
% 
% NO GUI version of streamControl.
% 
% datasetName  - Name of the dataset file (e.g., 'mysession.set')
% rawDataPath  - Path where the dataset is located (e.g., 'datasets/')
% oneChannel   - true/false flag if you want only one channel (false = all channels)
%
% Requires: eeglab with load_xdf plugin, LSL libraries for Matlab.
%
% Example usage:
%   streamControl_nogui('mysession.set', 'datasets/', false)

    % Setup global variables
    global running paused

    % Initialize EEG data and LSL
    if nargin < 3
        oneChannel = false;
    end
    if nargin < 2
        rawDataPath = 'datasets/';
    end

    % Load EEG dataset and prepare replayer
    fprintf('Loading dataset: %s%s%s\n', rawDataPath, datasetName, datasetName2);
    pamperEEGLab_mult(rawDataPath, datasetName, datasetName2, oneChannel);
    initializeReplayerState();

    % Start streaming EEG
    running = false;
    paused = false;

    fprintf('Starting EEG stream...\n');
    SendEEGdataBlindly_mult();

    % The stream will run inside SendEEGdataBlindly_2()
    % If you want to pause, resume, or stop manually, you can call:
    % pauseEEGstream(), resumeEEGstream(), stopEEGstream()

end

