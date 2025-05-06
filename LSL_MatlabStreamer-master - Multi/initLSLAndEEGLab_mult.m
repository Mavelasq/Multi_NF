function initLSLAndEEGLab_mult(startSample)
    global initialized EEG_labels leftOrRightTrialsCounter
    global samplecounter eventcounter eeg_outlet1 eeg_outlet2 nchans paused stopit srate marker_outlet1 marker_outlet2

    %% instantiate the library
    disp('Loading library...');
    lib = lsl_loadlib();
    eventcounter = 1;
    samplecounter = startSample;
    leftOrRightTrialsCounter = 1;

    % create stream info for first EEG stream
    disp('Creating streaminfo for EEG stream 1...');
    eeg_info1 = lsl_streaminfo(lib, 'MatlabEEG1', 'EEG', nchans, srate, 'cf_float32', 'sdfwerr32432');

    % create stream info for second EEG stream
    disp('Creating streaminfo for EEG stream 2...');
    eeg_info2 = lsl_streaminfo(lib, 'MatlabEEG2', 'EEG', nchans, srate, 'cf_float32', 'sdfwerr32433');

    % create stream info for marker stream for the first dataset
    marker_info1 = lsl_streaminfo(lib, 'MatlabMarkerStream1', 'Markers', 1, 0, 'cf_string', 'myuniquesourceid23443');

    % create stream info for marker stream for the second dataset
    marker_info2 = lsl_streaminfo(lib, 'MatlabMarkerStream2', 'Markers', 1, 0, 'cf_string', 'myuniquesourceid23443');

    %% Add meta-information (only to the first stream)
    chns1 = eeg_info1.desc().append_child('channels');
    for i = 1:length(EEG_labels)
        ch = chns1.append_child('channel');
        ch.append_child_value('label', EEG_labels{i});
        ch.append_child_value('unit', 'microvolts');
        ch.append_child_value('type', 'EEG');
    end

    chns2 = eeg_info2.desc().append_child('channels');
    for i = 1:length(EEG_labels)
        ch = chns2.append_child('channel');
        ch.append_child_value('label', EEG_labels{i});
        ch.append_child_value('unit', 'microvolts');
        ch.append_child_value('type', 'EEG');
    end

    %% Open EEG stream outlets
    disp('Opening EEG outlet for stream 1...');
    eeg_outlet1 = lsl_outlet(eeg_info1);

    disp('Opening EEG outlet for stream 2...');
    eeg_outlet2 = lsl_outlet(eeg_info2);

    %% Open marker outlets
    disp('Opening marker outlet for stream 1...');
    marker_outlet1 = lsl_outlet(marker_info1);

    disp('Opening marker outlet for stream 2...');
    marker_outlet2 = lsl_outlet(marker_info2);

    %% Initialize flags
    initialized = true;
    paused = false;
    stopit = false;
end
