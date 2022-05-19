% calcDifSeconds:  calculates difference in seconds between two vector date
% inputs. 
% INPUT: t1 - start time; t2 - end time. Both input as [YYYY MM DD HH MM
% SS]. t2 can be vector or vector array
% OUTPUT: dif - difference between two timepoints in seconds

function dif = calcDifSeconds(start, fin)
    start = double(start);
    fin = double(fin);
    d2s = 24*3600;    % convert from days to seconds
    d1 = datenum(start); % convert from datetime format to serial date time
    d1  = d2s*datenum(d1);  % convert to seconds
    
    dif = zeros(size(fin,1),1);
    for i = 1:size(fin,1)
        d2 = datenum(fin(i,:));
        d2  = d2s*datenum(d2);

        dif(i) = (d2-d1);
    end

end