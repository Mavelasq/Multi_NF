%short sonification demo
close all; clear all; clc;


%% set up path, libraries & dependencies:

addpath((['C:\MATLAB\eeglab2023.1_old']));


% LSL MATLAB library.
addpath(genpath(['D:\Documents\MATLAB\liblsl-Matlab']));

% LSL MATLAB Streamer (sends EEG data files over network in real-time).
path_streamer = ['D:\Documents\sonification\LSL_MatlabStreamer-master'];
addpath(path_streamer);

% NetUtil (used for streamControl, which sends data 
javaaddpath 'D:\Documents\sonification\netutil-1.0.0.jar'

% LSL
disp('Loading the library...');
lib = lsl_loadlib();

% now change directory to where streamer is.
cd(path_streamer)

% Initialize EEGLAB
eeglab;

% Parameters of synthetic dataset.
fs = 500; % Sampling frequency in Hz
duration = 900; % Duration in seconds
num_channels = 32;
beta_freq = 30; % Beta frequency in Hz

% Time vector
t = 0:1/fs:duration-1/fs;
num_samples = length(t);

% amplitude modulation.
ampMod = 0.5 + 0.5 * sin(2 * pi * (1/3) * t); % 10-sec slow modulation

% Generate beta oscillations for each channel
EEG_data = zeros(num_channels, num_samples);
for ch = 1:num_channels
    EEG_data(ch, :) = ...
        (sin(2 * pi * beta_freq * t + pi/2)) .* ampMod;
        % (sin(2 * pi * beta_freq * t + rand * 2 * pi)) .* ampMod; % Beta sine wave with random phase
end

% Create EEGLAB EEG structure
EEG = pop_importdata('setname', 'Synthetic_beta_EEG_Offphase', 'data', ...
    EEG_data, 'srate', fs, 'nbchan', num_channels);

% Set channel labels
for ch = 1:num_channels
    EEG.chanlocs(ch).labels = sprintf('Ch%d', ch);
end

% Add events every 500 ms
event_interval = 0.5; % seconds
num_events = floor(duration / event_interval);
EEG.event = struct('type', {}, 'latency', {});
for ev = 1:num_events
    EEG.event(ev).type = 'stim';
    EEG.event(ev).latency = ev * event_interval * fs;
end

% Save dataset
EEG = pop_saveset(EEG, 'filename', 'synthetic_betaOffPhase.set',...
    'filepath', [path_streamer '\datasets']);
eeglab redraw

% Initialize streaming of dataset over the network. 
% when promtped, enter filename: synthetic_beta.set
streamControl 

