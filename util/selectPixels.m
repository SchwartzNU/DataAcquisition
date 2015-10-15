function [selection, coords] = selectPixels(M)
%imagesc(M);
imagesc(var(M,[],3)./mean(M,3));
[x,y] = getpts(gcf);

coords = unique(round([x, y]),'rows');
selection = zeros(size(M));
selection(coords(:,1),coords(:,2)) = 1;

