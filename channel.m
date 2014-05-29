% Author: Wesley Tanner
% 2014-5-28

% This function represents an encode-decode vocoder pair.
% The channel is AWGN, and noise is added based on the input
% SNR (in dB).
%
% x = signal between +/- 1.
%
% valid channel types:
% AMR_NOVAD = 12.2 kbps AMR w/ VAD=OFF
% AMR = 12.2 kbps AMR w/ VAD=VAD2 (Motorola)
% AMR102 = 10.2 kbps AMR w/ VAD=VAD2
% AMR102_NOVAD = 10.2 kbps AMR w/ VAD=OFF
% AMR795 = 7.95 kbps AMR w/ VAD=VAD2
% AMR795_NOVAD = 7.95 kbps AMR w/ VAD=OFF
% AMR67 = 6.7 kbps AMR
% AMR67_NOVAD = 6.7 kbps AMR w/ VAD=OFF
% AMR59 = 5.9 kbps AMR
% AMR59_NOVAD = 5.9 kbps AMR w/ VAD=OFF
% PASSTHROUGH = no CODEC
%
% N = num_transcodes = 1, 2, .. N. Cell-to-cell call is 2.
% SNR = channel SNR (AWGN) in dB. Set to a high value for digital (e.g. bluetooth) audio connection.
%
% ***********
function y = channel(x, N, channel_type, SNR)
% N is the number of transcodes

% add noise samples
x = x + (1./(sqrt(10.^(SNR./10)./var(x))).*randn(length(x), 1))';

for index=1:N
  if strcmp(channel_type, 'PASSTHROUGH')
    y = x';
  else
    % scale and typecast x for the transcoder
    y = int16(2^13.*x);
    y = amr_decode(amr_encode(y, channel_type));
    y = double(y./2^13);
  end
end

end
