function [A_fit, phase_fit] = getSineWavePhaseAmpFit(D,period,halfWave)
%D is the data
%period in points
%X is amp, phase

%options = optimset('Display','iter','TolFun',1E-8);
%range(D)
%S = sin([(2*pi)/period:(2*pi)/period:pi]-pi/2);
%keyboard;
if halfWave    
    fitVals = fminbnd(@(x) sum((D - x.*sin([(2*pi)/period:(2*pi)/period:pi]-pi/2)).^2), -2*range(D), 0);
    A_fit = fitVals;
    S = sin([(2*pi)/period:(2*pi)/period:pi]-pi/2);
    keyboard;
else
    fitVals = fminsearch(@(x) sum((D - x(1).*sin((2*pi.*[1:period]+x(2))./period)).^2), [-range(D), period/4]);
    A_fit = fitVals(1);
    phase_fit = fitVals(2);
end



