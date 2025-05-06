function SendEEGdataBlindly_mult()
    global events1 events2 eegdata1 eegdata2 initialized running paused stopit
    global eeg_outlet1 eeg_outlet2 marker_outlet1 marker_outlet2 nchans srate

    persistent samplecounter1 samplecounter2 eventcounter1 eventcounter2

    if isempty(samplecounter1) || isempty(samplecounter2)
        samplecounter1 = 1;
        samplecounter2 = 1;
    end
    if isempty(eventcounter1) || isempty(eventcounter2)
        eventcounter1 = 1;
        eventcounter2 = 1;
    end

    if ~initialized
        initLSLAndEEGLab_mult(1);
    end

    disp('Now transmitting EEG data from both datasets simultaneously...');
    running = true;
    paused = false;
    stopit = false;

    starttime = clock;
    exampleSample_idx = 1300;
    precision = 2;

    while running && (~stopit)
        elapsedtime = etime(clock, starttime);
        expected_samples = floor(elapsedtime * srate);

        % Send next sample from dataset 1
        if samplecounter1 <= size(eegdata1,2) && samplecounter1 <= expected_samples
            eegsample1 = eegdata1(1:nchans, samplecounter1);
            eeg_outlet1.push_sample(double(eegsample1));
            samplecounter1 = samplecounter1 + 1;

            % Check and send event for dataset 1
            if eventcounter1 <= size(events1,1) && uint64(events1{eventcounter1,2}) == samplecounter1
                triggermsg1 = num2str(events1{eventcounter1,1});
                sampleInfoForTrigger1 = num2str(eegdata1(1, samplecounter1 + exampleSample_idx), precision);
                disp(['Dataset1 Event: Trial #', num2str(eventcounter1), ' ', triggermsg1 , ' ', sampleInfoForTrigger1]);
                sendUDPSignal(strcat(triggermsg1, ':', num2str(eventcounter1), ':', sampleInfoForTrigger1));
                marker_outlet1.push_sample({strcat(triggermsg1, ':', num2str(eventcounter1), ':', sampleInfoForTrigger1)});
                eventcounter1 = eventcounter1 + 1;
            end
        end

        % Send next sample from dataset 2
        if samplecounter2 <= size(eegdata2,2) && samplecounter2 <= expected_samples
            eegsample2 = eegdata2(1:nchans, samplecounter2);
            eeg_outlet2.push_sample(double(eegsample2));
            samplecounter2 = samplecounter2 + 1;

            % Check and send event for dataset 2
            if eventcounter2 <= size(events2,1) && uint64(events2{eventcounter2,2}) == samplecounter2
                triggermsg2 = num2str(events2{eventcounter2,1});
                sampleInfoForTrigger2 = num2str(eegdata2(1, samplecounter2 + exampleSample_idx), precision);
                disp(['Dataset2 Event: Trial #', num2str(eventcounter2), ' ', triggermsg2 , ' ', sampleInfoForTrigger2]);
                sendUDPSignal(strcat(triggermsg2, ':', num2str(eventcounter2), ':', sampleInfoForTrigger2));
                marker_outlet2.push_sample({strcat(triggermsg2, ':', num2str(eventcounter2), ':', sampleInfoForTrigger2)});
                eventcounter2 = eventcounter2 + 1;
            end
        end

        % Stop if both datasets are fully streamed
        if samplecounter1 > size(eegdata1,2) && samplecounter2 > size(eegdata2,2)
            disp('Finished streaming both datasets.');
            running = false;
            paused = false;
            samplecounter1 = 1;
            samplecounter2 = 1;
            eventcounter1 = 1;
            eventcounter2 = 1;
            stopit = true;
            break;
        end

        pause(0.001); % Tiny pause to avoid busy waiting
    end
end
