%{
Copyright 2018 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

% Tests the spherical harmonics encoding function (shhrirsymmetric) of
% HRIRs as well as the binaural rendering function
% shbinauralrendersymmetric by comparing the binaural stereo output to the
% standard pseudo-inverse binaural decoding method.

clearvars
close all
clc

% Import required ambisonic functions.
addpath('../ambisonics/shelf_filters/');

% Tolerated error margin equivalent to -60dB;
ERROR_MARGIN = 0.001;
SAMPLING_RATE = 48000;
INPUT = [1; zeros(511, 1)];
SOURCE_AZIMUTH_RAD = pi / 3;
SOURCE_ELEVATION_RAD =  pi / 4;

%% Tests the first order case with no shelf-filters.
AMBI_ORDER_1 = 1;

% Get the HRIRs for the first order decode.
HRIR_PATH_1 = '../hrtf_data/sadie/sadie_subject_002_symmetric_cube';
[ hrirMatrix1, ~, hrirAngles1 ] = loadhrirssymmetric( HRIR_PATH_1 );

% Encode the first order Ambisonic sound source.
encodedInput1 = ambencode(INPUT, AMBI_ORDER_1, SOURCE_AZIMUTH_RAD, ...
    SOURCE_ELEVATION_RAD);

% Decode input for the above virtual speaker array.
decodedInput1 = ambdecode(encodedInput1, hrirAngles1(:, 1), ...
    hrirAngles1(:, 2));

% Render binaurally using the 'standard' decoder method.
binauralOutputOld1 = binauralrendersymmetric(decodedInput1, hrirMatrix1);

% Render binaurally using SH-encoded HRIRs method.
shHrirs1 = shhrirsymmetric( HRIR_PATH_1, AMBI_ORDER_1 );
binauralOutputNew1 = shbinauralrendersymmetric(encodedInput1, shHrirs1);

% Check whether the binaural outputs using both methods are the same.
assert(size(binauralOutputNew1, 1) == size(binauralOutputOld1, 1));
for sample = 1:size(binauralOutputNew1, 1)
    assert((binauralOutputNew1(sample, 1) - ...
        binauralOutputOld1(sample, 1)) < ERROR_MARGIN);
    assert((binauralOutputNew1(sample, 2) - ...
        binauralOutputOld1(sample, 2)) < ERROR_MARGIN);
end

%% Tests the third order case with no shelf-filters.
AMBI_ORDER_3 = 3;

% Get the HRIRs for the third order decode.
HRIR_PATH_3 = '../hrtf_data/sadie/sadie_subject_002_symmetric_lebedev26';
[ hrirMatrix3, ~, hrirAngles3 ] = loadhrirssymmetric( HRIR_PATH_3 );

% Encode the third order Ambisonic sound source.
encodedInput3 = ambencode(INPUT, AMBI_ORDER_3, SOURCE_AZIMUTH_RAD, ...
    SOURCE_ELEVATION_RAD);

% Decode input for the above virtual speaker array.
decodedInput3 = ambdecode(encodedInput3, hrirAngles3(:, 1), ...
    hrirAngles3(:, 2));

% Render binaurally using the 'standard' decoder method.
binauralOutputOld3 = binauralrendersymmetric(decodedInput3, hrirMatrix3);

% Render binaurally using SH-encoded HRIRs method.
shHrirs3 = shhrirsymmetric( HRIR_PATH_3, AMBI_ORDER_3 );
binauralOutputNew3 = shbinauralrendersymmetric(encodedInput3, shHrirs3);

% Check whether the binaural outputs using both methods are the same.
assert(size(binauralOutputNew3, 1) == size(binauralOutputOld3, 1));
for sample = 1:size(binauralOutputNew3, 1)
    assert((binauralOutputNew3(sample, 1) - ...
        binauralOutputOld3(sample, 1)) < ERROR_MARGIN);
    assert((binauralOutputNew3(sample, 2) - ...
        binauralOutputOld3(sample, 2)) < ERROR_MARGIN);
end

%% Test the first order case with shelf-filters.
% Encode the first order Ambisonic sound source.
encodedInput1sf = ambishelffilter(encodedInput1, SAMPLING_RATE);

% Decode input for the above virtual speaker array.
decodedInput1sf = ambdecode(encodedInput1sf, hrirAngles1(:, 1), ...
    hrirAngles1(:, 2));

% Render binaurally using the 'standard' decoder method.
binauralOutputOld1sf = binauralrendersymmetric(decodedInput1sf, ...
    hrirMatrix1);

% Render binaurally using SH-encoded HRIRs method.
shHrirs1sf = shhrirsymmetric( HRIR_PATH_1, AMBI_ORDER_1, true );
binauralOutputNew1sf = shbinauralrendersymmetric(encodedInput1, ...
    shHrirs1sf);

% Check whether the binaural outputs using both methods are the same.
assert(size(binauralOutputNew1sf, 1) == size(binauralOutputOld1sf, 1));
for sample = 1:size(binauralOutputNew1sf, 1)
    assert((binauralOutputNew1sf(sample, 1) - ...
        binauralOutputOld1sf(sample, 1)) < ERROR_MARGIN);
    assert((binauralOutputNew1sf(sample, 2) - ...
        binauralOutputOld1sf(sample, 2)) < ERROR_MARGIN);
end

%% Test the third order case with shelf-filters.
% Encode the first order Ambisonic sound source.
encodedInput3sf = ambishelffilter(encodedInput3, SAMPLING_RATE);

% Decode input for the above virtual speaker array.
decodedInput3sf = ambdecode(encodedInput3sf, hrirAngles3(:, 1), ...
    hrirAngles3(:, 2));

% Render binaurally using the 'standard' decoder method.
binauralOutputOld3sf = binauralrendersymmetric(decodedInput3sf, ...
    hrirMatrix3);

% Render binaurally using SH-encoded HRIRs method.
shHrirs3sf = shhrirsymmetric( HRIR_PATH_3, AMBI_ORDER_3, true );
binauralOutputNew3sf = shbinauralrendersymmetric(encodedInput3, ...
    shHrirs3sf);

% Check whether the binaural outputs using both methods are the same.
assert(size(binauralOutputNew3sf, 1) == size(binauralOutputOld3sf, 1));
for sample = 1:size(binauralOutputNew3sf, 1)
    assert((binauralOutputNew3sf(sample, 1) - ...
        binauralOutputOld3sf(sample, 1)) < ERROR_MARGIN);
    assert((binauralOutputNew3sf(sample, 2) - ...
        binauralOutputOld3sf(sample, 2)) < ERROR_MARGIN);
end
