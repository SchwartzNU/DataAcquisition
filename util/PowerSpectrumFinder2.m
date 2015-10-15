function [Freq, Power] = PowerSpectrumFinder2(signal,samplerate);
% this function will find power spectrum of a signal
% input = signal in matrix with indiidual signals in a row, samplerate of
% a signal in Hz (eg. 10000)
% output = xvalues for powerspectrum, powerspectrum
%created by PJA, 9/29/2008
 
points = length(signal); %number of sample points
maxfreq = samplerate/2; %Nyquist
 
 
fft_signal = fft(signal, [], 2); % fourier transform of signal
tempps =  fft_signal.*conj(fft_signal); % the core of power sp, let's take only the real part, note in scaling this means multiplying by 2
tempps2 = real(tempps);
powerspec = (2*tempps2*(1/samplerate))/points; % power sp for each indiv.
mean_powerspec = mean(powerspec,1); % mean power spctrum
powerspec_xvalues = [0:2*maxfreq/points:maxfreq];
plotted_mean=mean_powerspec(1:points/2+1);
 
%figure;
%loglog(powerspec_xvalues,plotted_mean,'bo-');
[Freq]=powerspec_xvalues;
[Power]=plotted_mean;
%% Smooth PowerSP
%figure;
%SmoothPower=SmoothPowerSpectrum(plotted_mean, powerspec_xvalues, 1.5, 5);
%[Freq]=SmoothPower.Freq;
%[Power]=SmoothPower.PowerSpec;
 
%loglog(SmoothPower.Freq,SmoothPower.PowerSpec,'c');
 
%% NORM
 
%tempnorm=SmoothPower.PowerSpec;
%tempmax=max(tempnorm);
%norm=tempnorm/tempmax*10000;
 
%loglog(SmoothPower.Freq,norm,'ro');
