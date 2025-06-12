function calibrateSpeakers

% Need to find the calibration files
bpodPath = which('bpod');
% Go two levels up
root = fileparts(fileparts(bpodPath));
calibrationPath = [root filesep 'Bpod Local' filesep 'Calibration Files'];
addpath(calibrationPath);


% Setup the audio cues
trainLength = 1.5;
[clickTrain, quietTrain] = gen_test_cts(100, 0, trainLength);

% Wait for user and then play in the left speaker
disp('Press any key to play sound in left speaker...');
pause;

% Play audio on left speaker
audio_click_test(clickTrain, quietTrain, 1);
WaitSecs(trainLength);

% Wait for user and then play in the right speaker
disp('Press any key to play sound in right speaker...');
pause;

audio_click_test(clickTrain, quietTrain, 2);
WaitSecs(trainLength);

disp('done!');
