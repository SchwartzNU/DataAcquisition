function n = cellname2datenum(cellName)
%cellname is mmddyy followed by rig letter then c then cell number
%this function gives back the date of the experiment as a datenum

n = datenum([cellName(1:2) '/' cellName(3:4) '/' cellName(5:6)], 20);