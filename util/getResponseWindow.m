function [shiftVal, Tstart Tend] = getResponseWindow(S,th)
%th is a percent of max signal
S = S - min(S);
S = S./max(abs(S));

[peak, peakLoc] = max(S);
shiftVal = round(length(S)/2) - peakLoc;
S = circshift(S,shiftVal);

midPoint = round(length(S)/2);

Tstart = getThresCross(S(1:midPoint),th,1);
if isempty(Tstart)
    disp('warning: start point not found, setting to 1');
    Tstart = 1;
else
    Tstart = Tstart(end);
end

Tend = midPoint - 1 + getThresCross(S(midPoint:end),th,-1);
if isempty(Tend)
    disp('warning: end point not found, setting to length of signal');
    Tend = length(S);
else
    Tend = Tend(1);
end

%keyboard;






