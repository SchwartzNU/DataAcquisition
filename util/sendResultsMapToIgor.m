function s = sendResultsMapToIgor(node,fname)
basedir = '~/hdf5_temp/';

keys = node.custom.get('results').keySet.toArray;

s = struct;
for i=1:length(keys)
    curVal = node.custom.get('results').get(keys(i));
    if strcmp(keys(i),'epochResults')
        %skip
    else
        if isa(curVal,'java.lang.String')
            curVal = curVal.toString;
        elseif isa(curVal,'java.lang.String[]')
            curCellArray = {};
            for j=1:length(curVal)
                curCellArray{j} = curVal(j).toCharArray';
            end
            curVal = curCellArray;
        elseif isa(curVal,'java.lang.Object[]') %array of numbers
            curCellArray = {};
            for j=1:length(curVal)
                curCellArray{j} = curVal(j);
                if isempty(curCellArray{j})
                    curCellArray{j} = nan;
                end
            end
            curVal = curCellArray;
        end
        s.(keys(i)) = curVal;
    end
end

%write hdf5 file
options.overwrite = 1;
if nargin<2
    fname = input('Figure Name: ', 's');
end
exportStructToHDF5(s,[fname '.h5'],'FigData',options);
movefile([fname '.h5'], [basedir fname '.h5']);

