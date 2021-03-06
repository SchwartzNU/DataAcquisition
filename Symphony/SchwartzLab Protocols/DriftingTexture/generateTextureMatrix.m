function [] = generateTextureMatrix(config)
    imagesDir = 'C:\Users\Greg\Documents\Matlab\Symphony\StimulusImages\'; 
    Nconditions = length(config.pixelBlur)*length(config.randSeed);
    z=1;    
    for i=1:length(config.pixelBlur)
        for j=1:length(config.randSeed)
            disp(['Generating texture ' num2str(z) ' of ' num2str(Nconditions)]);
            fname = [imagesDir config.baseName '_' num2str(i) '_' num2str(j) '.png'];
            tex = textureGenerator(1140, 912, config.pixelBlur(i), config.randSeed(j));    
            imwrite(tex,fname);
            z=z+1;
        end
    end
end

