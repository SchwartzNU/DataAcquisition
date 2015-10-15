function D = loadIDSTimeSeries(filename,nCh,nX,nT)
fid = fopen(filename, 'r');
%fseek(fid, 6, 'bof'); %assumes channel 1?
Xpixels = nX;
Tpixels = nT;
D = zeros(Xpixels,Tpixels);
D = fread(fid, [Xpixels Tpixels], 'uint16', 2*(nCh-1), 'l');
fclose(fid);

