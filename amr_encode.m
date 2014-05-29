% Encode the input PCM samples using the AMR vocoder.
% This function depends on the 3GPP AMR reference 
% implementation, compiled and placed in the current 
% working directory.
%
% valid modes are described in channel.m
% speech_data = int16 samples

function data = amr_encode(speech_data, mode)

fid = fopen('encode.inp', 'w');
fwrite(fid, speech_data, 'int16');
fclose(fid);

if strcmp(mode,'AMR_NOVAD')
    system('./encoder MR122 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR')
    system('./encoder -dtx MR122 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR102')
    system('./encoder -dtx MR102 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR102_NOVAD')
    system('./encoder MR102 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR795')
    system('./encoder -dtx MR795 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR795_NOVAD')
    system('./encoder MR795 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR67_NOVAD')
    system('./encoder MR67 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR67')
    system('./encoder -dtx MR67 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR59_NOVAD')
    system('./encoder MR59 encode.inp encode.cod 1>NUL 2>NUL');
elseif strcmp(mode,'AMR59')
    system('./encoder -dtx MR59 encode.inp encode.cod 1>NUL 2>NUL');
else
    % default to AMR122/EFR, no VAD
    system('./encoder MR122 encode.inp encode.cod 1>NUL 2>NUL');
end

fid = fopen('encode.cod', 'r');
data = fread(fid, 'uint16');
fclose(fid);

system('rm encode.inp');
system('rm encode.cod');
