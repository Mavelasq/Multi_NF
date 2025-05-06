% This function is called once when the figure is loaded. After that, this
% function is never to be called again, because eeglab will get cranky and end
% up being in a very bad state.
% This function starts eeglab, loads two datasets, and then stores the events
% and other information into separate data structures for each dataset.

function [EEG1, EEG2] = pamperEEGLab_mult(rawdatapath, datasetName1, datasetName2, oneChannel)
global events1 events2 ALLEEG CURRENTSET eegdata1 eegdata2 nchans srate EEG_labels1 EEG_labels2

disp 'eeglab setup';

disp('eeglab is being loaded..');
% start eeglab
[ALLEEG, EEG1, CURRENTSET, ALLCOM] = eeglab; %#ok<*ASGLU>
% load first dataset
EEG1 = pop_loadset('filename',datasetName1,'filepath',rawdatapath);
% copy changes to ALLEEG
[ALLEEG, EEG1, CURRENTSET] = eeg_store(ALLEEG, EEG1);

% load second dataset
EEG2 = pop_loadset('filename',datasetName2,'filepath',rawdatapath);
% copy changes to ALLEEG
[ALLEEG, EEG2, CURRENTSET] = eeg_store(ALLEEG, EEG2);

eeglab redraw;

% eeglab was started successfully, use info and data for both datasets
eegdata1 = EEG1.data;
eegdata2 = EEG2.data;
nchans = EEG1.nbchan;
%nchans2 = EEG2.nbchan;
srate = EEG1.srate;  
samples1 = EEG1.pnts; 
samples2 = EEG2.pnts; 

% fill the cell array with the type of the event and the sample number in
% which it occurred. first row contains the types, second row the sample.
events1 = LoopOverEvents(EEG1);
events2 = LoopOverEvents(EEG2);

if oneChannel
    EEG_labels1{1} = EEG1.chanlocs(1).labels;
    EEG_labels2{1} = EEG2.chanlocs(1).labels;
else 
    % store labels from the first dataset into EEG_labels1
    for i = 1 : EEG1.nbchan
        EEG_labels1{i} = EEG1.chanlocs(i).labels;
    end
    % store labels from the second dataset into EEG_labels2
    for i = 1 : EEG2.nbchan
        EEG_labels2{i} = EEG2.chanlocs(i).labels;
    end
end

%% helper function to get the events and latencies from the dataset
function events = LoopOverEvents(EEG)
    events = cell(length(EEG.event),2);
    for j = 1 : length(EEG.event)
        % first column: events in every row
        events{j,1} = char(EEG.event(j).type);
        % second column: corresponding latency in every row
        events{j,2} = EEG.event(j).latency;
    end
end

end
