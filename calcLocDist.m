% calcLocDist: calculates total distance as point vector and summation
% INPUT:  location matrix (2 [x,y] by N [observations])
%OUTPUT:  [vector, sum]. vector contains distance moved between each point;
%sum contains total movement across all points
function [dvec, dsum] = calcLocDist(loc)
    dvec = zeros(1,length(loc)-1);
    for i = 1:length(loc)-1
        dvec(i) = pdist([loc(1,i), loc(2,i);loc(1,i+1), loc(2,i+1)]);
    end
    dsum = sum(dvec);
end