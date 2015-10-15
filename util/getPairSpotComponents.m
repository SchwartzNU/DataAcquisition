function [component1, component2] = getPairSpotComponents(node)
%get component traces (single spots)
pair_pos = str2num(node.splitValue);
X1 = pair_pos(1);
Y1 = pair_pos(2);
X2 = pair_pos(3);
Y2 = pair_pos(4);

singles_root = node.parent.parent.children.valueByIndex(1);
ch = singles_root.children;
component1 = [];
component2 = [];
for i=1:ch.length
    %keyboard;
   if isequal(str2num(ch.valueByIndex(i).splitValue), [X1 Y1])
       component1 = ch.valueByIndex(i);
   elseif isequal(str2num(ch.valueByIndex(i).splitValue), [X2 Y2])
       component2 = ch.valueByIndex(i);
   end       
end