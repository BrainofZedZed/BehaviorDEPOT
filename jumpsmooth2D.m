function [rx,ry] = jumpsmooth2D(pstamps, rx, ry, gapthresh, jumpthresh, nanradius, boxwidth)   

%REMOVES LARGE JUMPS FROM 2D POSITION TRACKING TIME SERIES DATA, THEN DOES
%BOXCAR SMOOTHING ON THE RESULT

%pstamps = time stamps of position data
%rx, ry = position data
%gapthresh = largest gap (in samples) across which to interpolate missing values after jumpremoval
%jumpthresh = movement speed that defines a large jumps (in pixels per sample)
%nanradius = radius (in samples) surrounding jump event to fill in with NaNs
%boxwidth = width of boxcar for smoothing

boxkernel = ones(boxwidth,1)/boxwidth;

%%%filter out big position jumps
xdiff=[NaN; diff(rx)];
ydiff=[NaN; diff(ry)];
rspd=sqrt(xdiff.*xdiff + ydiff.*ydiff);
jmps = find(rspd>jumpthresh);
rx(jmps)=NaN;
ry(jmps)=NaN;
jmps = jmps(find(jmps>nanradius));
jmps = jmps(find(jmps<(end-nanradius)));
for i=-nanradius:nanradius
    rx(jmps+i)=NaN; ry(jmps+i)=NaN; 
end

%%%fill in missing x values
rx_nandex=find(isnan(rx)); %%indices of NaNs
nd_rx=[100; diff(rx_nandex)]; %%how far back was previous NaN?
rx_firstnansdex=find(nd_rx>1); %%indices of indices of NaNs that are the first of a sequence
nanlengths=diff(rx_firstnansdex); %%lengths of the sequences
rx_firstnansdex=rx_firstnansdex(find(nanlengths<gapthresh)); %%indicies of NaN sequences less than half a second long
nanlengths=nanlengths(find(nanlengths<gapthresh)); %%lengths of NaN sequences less than one second long
%%construct a list of indices for NaN values that can be filled in by interpolation
filldex=[];
for dd=1:length(nanlengths)-1  
    filldex=[filldex rx_nandex(rx_firstnansdex(dd)):rx_nandex((rx_firstnansdex(dd))+nanlengths(dd)-1)];
end
if ~isnan(filldex)
    fillrx=interp1(pstamps(find(~isnan(rx))),rx(find(~isnan(rx))),pstamps(filldex),'linear'); %%interpolate missing values
    rx(filldex)=fillrx;
end
rx = conv(rx,boxkernel,'same');

%%%fill in missing y values
ry_nandex=find(isnan(ry)); %%indices of NaNs
nd_ry=[100; diff(ry_nandex)]; %%how far back was previous NaN?
ry_firstnansdex=find(nd_ry>1); %%indices of indices of NaNs that are the first of a sequence
nanlengths=diff(ry_firstnansdex); %%lengths of the sequences
ry_firstnansdex=ry_firstnansdex(find(nanlengths<gapthresh)); %%indicies of NaN sequences less than half a second long
nanlengths=nanlengths(find(nanlengths<gapthresh)); %%lengths of NaN sequences less than one second long
%%construct a list of indices for NaN values that can be filled in by interpolation
filldex=[];
for dd=1:length(nanlengths)  
    filldex=[filldex ry_nandex(ry_firstnansdex(dd)):ry_nandex((ry_firstnansdex(dd))+nanlengths(dd)-1)];
end
if ~isnan(filldex)
    fillry=interp1(pstamps(find(~isnan(ry))),ry(find(~isnan(ry))),pstamps(filldex),'linear'); %%interpolate missing values
    ry(filldex)=fillry;
end
ry = conv(ry,boxkernel, 'same');

