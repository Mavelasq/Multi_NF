%short sonification demo
close all; 
clear vars; 
clc;

%% ========== PARAMETERS ==========
% Paths
eeglab_path     = 'C:\MATLAB\eeglab2023.1_old';
lsl_path        = 'D:\Documents\MATLAB\liblsl-Matlab';
streamer_path   = 'D:\Documents\sonification\LSL_MatlabStreamer-master\New Folder';
sonif_path      = 'D:\Documents\sonification';

% Stream configuration
%stream_name = {'LiveAmpSN-101410-0951'};
stream_name     = {'MatlabEEG1','MatlabEEG2'};
SUBJ            = {'sub1', 'sub2'};
chan_num        = 32;  % number of channels
chan            = 20;  % index of channel to use
sample_rate     = 500;
simulate_mode   = true;

%filter parameters
filter_lower    = 8;
filter_upper    = 12;
filter_type     = 'bandpass';
filter_enabled  = false;
filter_order    = 10;

% Processing parameters
buffSize        = 4;         % buffer size in chunks
pause_time      = 0.1;       % processing loop pause
norm_output     = false;     % normalize amplitudes
window_size     = 1;
step_size = sample_rate * 0.5; % 0.5 second steps (250 samples)
buffer_size = sample_rate * window_size; % 1 second buffer (500 samples)


%OSC parameters
ip_address      = '127.0.0.1';
port_num        = 3000;

% Musical parameters
c_major_midi    = [60 62 64 65 67 69 71 72]; % C major scale MIDI notes

%% ========== INITIALIZATION ==========
% Set up paths
addpath(eeglab_path);
addpath(genpath(lsl_path));
addpath(streamer_path);
addpath(sonif_path);
cd(sonif_path);

% Add Java library
javaaddpath netutil-1.0.0.jar;

% Load LSL library
disp('Loading the library...');
lib = lsl_loadlib();

%% Here is where we can initialize parameter settings for processing.
if filter_enabled
    bpf = designfilt('bandpassiir', ...
        'FilterOrder', filter_order, ...
        'PassbandFrequency1', filter_lower, ...
        'PassbandFrequency2', filter_upper, ...
        'SampleRate', sample_rate, ...  
        'DesignMethod', 'cheby1');
end 

    %% create Outlet
    disp('Creating a new streaminfo...');
    % stream_info args: LSL library variable, stream name, content, # channels
    % per sample, sampling rate of data source, data type, unique identifier of
    % source device.
     info = lsl_streaminfo(lib,'FBStream','Feedback Values',...
         2,10,'cf_float32','sdfwerr33232'); % sampling rate corresponds to pause at the end  (?)
    
    disp('Opening an outlet...');
    outlet = lsl_outlet(info);

%% Resolve Streams
disp('Resolving EEG streams...');

% Configuration
SUBJ = {'sub1', 'sub2'};
stream_labels = {'MatlabEEG1', 'MatlabEEG2'};
max_attempts = 50;
attempt_wait = 0.1;

% Initialize structure
stream = struct();
for s = 1:length(SUBJ)
    stream.(SUBJ{s}) = struct('inlet', [], 'name', stream_labels{s}, 'val', []);
end

% Resolution with retries
all_resolved = false;
attempt = 0;
while ~all_resolved && attempt < max_attempts
    attempt = attempt + 1;
    all_resolved = true;
    
    % Try to resolve all streams at once
    streams = lsl_resolve_all(lib, 1);
    
    % Match found streams to subjects
    for s = 1:length(SUBJ)
        if isempty(stream.(SUBJ{s}).inlet)
            label = stream_labels{s};
            for i = 1:length(streams)
                if strcmp(streams{i}.name(), label)
                    stream.(SUBJ{s}).inlet = lsl_inlet(streams{i});
                    fprintf('Connected %s to stream "%s"\n', SUBJ{s}, label);
                    break;
                end
            end
            if isempty(stream.(SUBJ{s}).inlet)
                all_resolved = false;
            end
        end
    end
    
    if ~all_resolved
        pause(attempt_wait);
    end
end

if all_resolved
    disp('All EEG streams resolved successfully.');
else
    warning('Failed to resolve all streams after %d attempts', max_attempts);
    % List which streams were not found
end

%% Create Figure and Bar Handle for Plotting
% h_fig = figure('units', 'normalized', 'outerposition', [0.35 0 0.3 0.7]);
% h_bar = bar([0,0], 'FaceColor', [0.1 0.7 0.9]);
% ylim([0 1]); ylabel('8-12 Hz Amplitude');
% set(gca, 'Color', 'white', 'XColor', 'k', 'YColor', 'k');
% set(gcf, 'Color', 'white');
% grid on;
% drawnow;
% 
ok = 1;

% First Bar Graph (Top)
%subplot(2,1,1);
h_bar1 = bar(0, 'FaceColor', [0.1 0.7 0.9]);  % Cyan bar
ylim([0 1]); 
ylabel('8-12 Hz Amplitude');
set(gca, 'Color', 'white', 'XColor', 'k', 'YColor', 'k', 'XTick', []);
grid on;

% Second Bar Graph (Bottom)
% subplot(2,1,2);
% h_bar2 = bar(0, 'FaceColor', [0.9 0.2 0.2]);  % Red bar
% ylim([0 1]);
% ylabel('12-16 Hz Amplitude');
% set(gca, 'Color', 'white', 'XColor', 'k', 'YColor', 'k', 'XTick', []);
% grid on;

% Common Figure Styling
set(gcf, 'Color', 'white');
drawnow;


%% Initialize stream processing structures
disp('Initializing stream processing...');

for i = 1:length(SUBJ)
    % Verify the inlet exists
    if isempty(stream.(SUBJ{i}).inlet)
        warning('No inlet found for %s - stream may not be available', SUBJ{i});
        continue;
    end
    
    % update stream object with fields for data processing.
    stream.(SUBJ{i}).idx = 1;
    stream.(SUBJ{i}).buffer = [];
    stream.(SUBJ{i}).chunk = zeros(chan_num,1);
    stream.(SUBJ{i}).data = [];
    
    fprintf('Initialized processing for %s\n', SUBJ{i});
end
%% fill buffer once:
% Preallocate buffers
for i = 1:length(SUBJ)
    stream.(SUBJ{i}).buffer = zeros(chan_num, buffer_size);
    stream.(SUBJ{i}).fill_index = 1;
end


%% fill buffer once:
fprintf('--- Starting buffer fill process ---\n');

% Initialize timers
overall_start = tic;
stream1_total_time = 0;
stream2_total_time = 0;
last_data_time = tic;

while stream.(SUBJ{1}).fill_index <= buffer_size && ...
      stream.(SUBJ{2}).fill_index <= buffer_size
    
    % === Pull chunks ===
    [stream.(SUBJ{1}).chunk, ts1] = stream.(SUBJ{1}).inlet.pull_chunk();
    [stream.(SUBJ{2}).chunk, ts2] = stream.(SUBJ{2}).inlet.pull_chunk();
    
    % === Process each stream ===
    for i = 1:length(SUBJ)
        chunk = stream.(SUBJ{i}).chunk;
        if isempty(chunk)
            continue;
        end
        
        % Debug output
        fprintf('%s chunk original size: %d×%d\n', SUBJ{i}, size(chunk,1), size(chunk,2));
        
        % Ensure channels × samples orientation
        if size(chunk, 1) ~= chan_num
            chunk = chunk';
            fprintf('%s chunk transposed to: %d×%d\n', SUBJ{i}, size(chunk,1), size(chunk,2));
        end
        
        % Fill buffer
        n_samples = size(chunk, 2);
        idx = stream.(SUBJ{i}).fill_index;
        remaining = buffer_size - idx + 1;
        to_write = min(remaining, n_samples);
        
        if to_write > 0
            stream.(SUBJ{i}).buffer(:, idx:idx+to_write-1) = chunk(:, 1:to_write);
            stream.(SUBJ{i}).fill_index = idx + to_write;
            fprintf('Filled %d samples into buffer\n', to_write);
        end
    end
    
    pause(0.01); % Small pause to prevent CPU overload
end

% === Final Synchronization Check ===
sync_diff = abs(stream.(SUBJ{1}).fill_index - stream.(SUBJ{2}).fill_index);
if sync_diff > 0
    warning('Streams desynchronized by %d samples!', sync_diff);
else
    fprintf('Streams filled and synchronized at %d samples.\n', buffer_size);
end

% === Timing Summary ===
overall_elapsed = toc(overall_start);
fprintf('\n--- Buffer Fill Complete ---\n');
fprintf('%s total pull time: %.4f sec\n', SUBJ{1}, stream1_total_time);
fprintf('%s total pull time: %.4f sec\n', SUBJ{2}, stream2_total_time);
fprintf('Total wall-clock time: %.4f sec\n', overall_elapsed);
fprintf('Time difference between streams: %.4f sec\n', abs(stream1_total_time - stream2_total_time));


%% once buffer is initialized, implement ring buffer.

%% once buffer is initialized, implement ring buffer.
disp('--- Starting ring buffer processing ---');

while ok
    % === Pull new data ===
    [chunk1, ts1] = stream.(SUBJ{1}).inlet.pull_chunk();
    [chunk2, ts2] = stream.(SUBJ{2}).inlet.pull_chunk();
    
    % Skip iteration if no new data
    if isempty(chunk1) || isempty(chunk2)
        pause(0.01);
        continue;
    end
    
    % === Process each subject ===
    for i = 1:length(SUBJ)
        subj = SUBJ{i};
        chunk = stream.(subj).chunk;

        % Transpose if necessary to get [channels × samples]
        if size(chunk,1) ~= chan_num
            chunk = chunk';
        end

        % Get number of new samples
        n_samples = size(chunk, 2);
        
        % Skip if no new samples
        if n_samples == 0
            continue;
        end
        
        % Update buffer using ring buffer approach
        current_end = stream.(subj).fill_index;
        remaining_space = buffer_size - current_end + 1;
        
        if n_samples <= remaining_space
            % Case 1: All new samples fit in remaining space
            stream.(subj).buffer(:, current_end:current_end+n_samples-1) = chunk;
            stream.(subj).fill_index = current_end + n_samples;
        else
            % Case 2: Need to wrap around
            % Part 1: Fill remaining space
            stream.(subj).buffer(:, current_end:end) = chunk(:, 1:remaining_space);
            
            % Part 2: Fill beginning of buffer with remaining samples
            remaining_samples = n_samples - remaining_space;
            stream.(subj).buffer(:, 1:remaining_samples) = chunk(:, remaining_space+1:end);
            
            stream.(subj).fill_index = remaining_samples + 1;
        end
        
        % Always maintain full buffer by getting the most recent buffer_size samples
        if stream.(subj).fill_index == 1
            current_buffer = stream.(subj).buffer;
        else
            current_buffer = [stream.(subj).buffer(:, stream.(subj).fill_index:end), ...
                            stream.(subj).buffer(:, 1:stream.(subj).fill_index-1)];
        end

        % Optional: Filter
        if filter_enabled
            stream.(subj).filtered = filter(bpf, current_buffer(chan,:));
        else
            stream.(subj).filtered = current_buffer(chan,:);
        end
    end   
        % Compute mean amplitude
        signal1= hilbert(stream.(SUBJ{1}).filtered);
        signal2= hilbert(stream.(SUBJ{2}).filtered);
                
        signal1 = stream.(SUBJ{1}).filtered;  % Complex analytic signal from Hilbert transform
        signal2 = stream.(SUBJ{2}).filtered;  % Complex analytic signal from Hilbert transform
        
        % Ensure both signals are column vectors
        signal1 = signal1(:);
        signal2 = signal2(:);
        
        % Calculate numerator: absolute value of dot product
        numerator = sum(abs(signal1 .* signal2));
        
        % Calculate denominators
        denom1 = sqrt(sum(abs(signal1).^2));
        denom2 = sqrt(sum(abs(signal2).^2));
        
        % Final coherence value
        coherence = numerator / (denom1 * denom2);

        disp(coherence)
            
        set(h_bar1, 'YData', coherence);

        % Update bar plot
        % if i == 1
        %     set(h_bar1, 'YData', stream.(SUBJ{1}).val);
        % else
        %     set(h_bar2, 'YData', stream.(SUBJ{2}).val);
        % end

        drawnow;
        %pause(pause_time); % throttle loop

        % Simulate mode pause
        if simulate_mode
            pause(max(length(ts1), length(ts2))/sample_rate);
        end
end