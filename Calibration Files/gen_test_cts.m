function [ct_1, ct_2] = gen_test_cts(ct_1, ct_2, stim_t)
% Generate two poissin click trains, with different rates, to test clicks
%
% INPUT
% ct_1, ct_2: Click rates 1 and 2, used to generate click train
% stim_t: Stimulus time or stimulus duration, in seconds
%
% OUTPUT:
% ct_1, ct_2: Click trains 1 and 2 (left hand side!)

%% Initialize and program PulsePal
PulsePal
load Click2AFCPulsePalProgramUP2.mat
ProgramPulsePal(ParameterMatrix);
OriginalPulsePalMatrix = ParameterMatrix;

% Generate the fast and slow click trains
ct_1 =GeneratePoissonClickTrain_PulsePal(ct_1, stim_t);
ct_2 = GeneratePoissonClickTrain_PulsePal(ct_2, stim_t);