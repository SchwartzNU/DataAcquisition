function [freqs, powerMatrix] = textureFreqDistribution(N, imageSize, pixelBlur)
    L = length(pixelBlur);
    freqs = 1.38/2*linspace(0,1,imageSize/2+1);
    
    powerMatrix = zeros(L, imageSize/2+1);
    
    for i=1:L
       i
       for j=1:N
           tex = textureGenerator(imageSize, imageSize, pixelBlur(i), j);
           tex = (double(tex)-127)/127; %units of contrast
           F = fft2(tex);
           power = abs(diag(F));
           powerMatrix(i,:) = powerMatrix(i,:) + power(1:imageSize/2+1)';           
       end
        
    end

powerMatrix = powerMatrix ./ N;