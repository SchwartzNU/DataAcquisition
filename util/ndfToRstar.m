function [] = ndfToRstar(node,T)
%table T has colums: rig, ndf, R* for monitor at level 0.5

R = node.custom.get('results');
cellNames = R.get('protocolSettings_acquirino_cellBasename');
ndfs_cell = R.get('splitOnNDF');

T_rigs = [T{:,1}];
T_ndfs = [T{:,2}];
T_Rstar = [T{:,3}];


L = length(cellNames);
rigs = zeros(1,L);
ndfs = zeros(1,L);
Rstar = zeros(1,L);

for i=1:L
    if findstr('B',cellNames(i))
        rigs(i) = 'B';
    elseif findstr('F',cellNames(i))
        rigs(i) = 'F';
    else
        error('Rig not B or F');
    end
    ndfs(i) = str2double(ndfs_cell(i));
end
        
for i=1:L
   ind = find(T_rigs==char(rigs(i)) & T_ndfs==ndfs(i));   
   if isempty(ind)
       error('Calibration value not found');
   end
   Rstar(i) = T_Rstar(ind); 
end

R.put('Rstar',Rstar);

