% Author: Wesley Tanner
% 2014-5-28

clear;

% ***********
% channel parameters
%
% channel modes:
% AMR = 12.2 kbps AMR w/ VAD=VAD2 (Motorola)
% AMR102 = 10.2 kbps AMR w/ VAD=VAD2
% AMR795 = 7.95 kbps AMR w/ VAD=VAD2
% AMR67 = 6.7 kbps AMR
% AMR59 = 5.9 kbps AMR
% PASSTHROUGH = no CODEC
%
% SNR = channel SNR (AWGN) in dB. Set to a high value for digital (e.g. bluetooth) audio connection.
%
% training filename is a wav file with voice sampled at 8000 Hz.
% num_vectors_per_mode = the number of wav files to generate for each mode.
% length_training = number of samples desired for the training input.
% ***********

channel_modes = {'AMR', 'AMR102', 'AMR795', 'AMR67', 'AMR59', 'PASSTHROUGH'};
SNR = 30;
training_filename = 'train.wav';
length_training = 8000*2;
num_vectors_per_mode = 300;
output_directories = {'training', 'test'};

% ***********
% Create/clean output directories
% ***********

for directory = output_directories
  if exist(directory{1}, "dir") ~= 7
    fprintf('creating directory: %s\n', directory{1})
    fflush(stdout);
    mkdir(directory{1});
  else
    % clean the directory out
    fprintf('directory %s exists, cleaning.\n', directory{1});
    rmdir(directory{1}, "s");
    mkdir(directory{1});
  end
end

% ***********
% Read and preprocess training wav file
% ***********

[s_in, rate, bps] = wavread(training_filename);
if rate ~= 8000
  disp('input wav file must be sampled at 8000 Hz.');
  exit(1);
end

% crop to length_training samples, if longer than desired
if length(s_in) > length_training
  s_in = s_in(1:length_training);
end

% normalize to 0.75 maximum amplitude
s_in = 0.75 .* (s_in / max(s_in));

% ***********
% MAIN LOOP
% ***********

for directory = output_directories
  for channel_mode = channel_modes
    fprintf('creating %d files for %s, channel %s\n', num_vectors_per_mode, directory{1}, channel_mode{1});
    fflush(stdout);

    mkdir_arg = sprintf('%s/%s', directory{1}, channel_mode{1});
    if exist(mkdir_arg, "dir") ~= 7
      mkdir(mkdir_arg);
    end

    for index = 1:num_vectors_per_mode
      % compute a random delay, in samples. 0-0.5 sec.
      delay_samples = zeros(round(rand(1) .* 4000+1), 1);
      s_delay = cat(1, delay_samples, s_in);

      % compute a random amplitude, from 50% to 100%
      a = 0.5 .* (rand(1) + 1);

      % add padding to the end to account for transcoding delay
      s_pad = cat(1, s_delay, zeros(1000, 1));

      % 1st transcode
      s_out = channel(a.*s_pad', 1, channel_mode{1}, SNR);

      % remove added delay
      s_out = s_out(length(delay_samples)+1:length(delay_samples) + length(s_in));

      output_filename = sprintf('%s/%s/%d.wav', directory{1}, channel_mode{1}, index);
      wavwrite(s_out, output_filename);
    end
  end
end
