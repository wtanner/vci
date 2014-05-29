% Author: Wesley Tanner
% 2014-5-28

function speech_data = amr_decode(data)

fid = fopen('decode.cod', 'w');
fwrite(fid, data, 'uint16');
fclose(fid);

system('./decoder decode.cod decode.out 1>NUL 2>NUL');

fid = fopen('decode.out', 'r');
speech_data = fread(fid, 'int16');
fclose(fid);

system('rm decode.cod');
system('rm decode.out');
