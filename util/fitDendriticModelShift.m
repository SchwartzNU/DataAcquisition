function modelRatio = fitDendriticModelShift(b,respRatio,spotLoc,cell1Image,cell2Image)
shiftX = round(b(1)*1E3)
shiftY = round(b(2)*1E3)

Nspots = size(spotLoc,1);

modelResp_c1 = zeros(Nspots,1);
modelResp_c2 = zeros(Nspots,1);

spotLoc(:,1) = spotLoc(:,1) + shiftX;
spotLoc(:,2) = spotLoc(:,2) + shiftY;

[r,c] = size(cell1Image);

for j=1:Nspots
    if spotLoc(j,1)>c || spotLoc(j,1)<= 0 || spotLoc(j,2)>r || spotLoc(j,2)<=0
        modelResp_c1(j) = nan;
        modelResp_c2(j) = nan;   
    else
        modelResp_c1(j) = cell1Image(spotLoc(j,1),spotLoc(j,2));
        modelResp_c2(j) = cell2Image(spotLoc(j,1),spotLoc(j,2));
    end
end

modelResp_c1 = (modelResp_c1 - mean(modelResp_c1))./std(modelResp_c1);
modelResp_c2 = (modelResp_c2 - mean(modelResp_c2))./std(modelResp_c2);

%temp hack, try difference
modelRatio = modelResp_c1 - modelResp_c2

%keyboard;
%v = nansum((respRatio-modelRatio).^2);
