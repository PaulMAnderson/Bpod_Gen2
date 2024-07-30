function audio_click_test(ct_1, ct_2, lr_trial)
% FIRST RUN gen_test_cts
%
% INPUT:
% ct_1, ct_2: the OUTPUT of gen_test_cts
% lr_trial:   1 is left 2 is right

pause(0.5)

% Ensure that click train are not empty and align first click
if ~isempty(ct_1) && ~isempty(ct_2);
    ct_2 = ct_2-ct_2(1)+ct_1(1);
elseif isempty(ct_2) && ~isempty(ct_1);
    ct_2 = ct_1(1);
elseif isempty(ct_1) && ~isempty(ct_2);
    ct_1 = ct_2(1);
else
    error('No clicks!')
end

% Trial types and definition for reward and punishment
switch lr_trial; 
    case 1 % left is click train 1
        SendCustomPulseTrain(1, ct_2, ones(1,length(ct_2))*5);
        SendCustomPulseTrain(2, ct_1, ones(1,length(ct_1))*5);
    case 2 % right is click train 1
        SendCustomPulseTrain(1, ct_1, ones(1,length(ct_1))*5);
        SendCustomPulseTrain(2, ct_2, ones(1,length(ct_2))*5);
end

TriggerPulsePal('11'); % Launches cklick train

end