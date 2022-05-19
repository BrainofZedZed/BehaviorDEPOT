function caplot(sig, norm)
% modified from MIN1PIPE

if ~exist('norm', 'var')
    norm = 1;
end

if norm
    for i = 1: size(sig, 1)
        sigt(i, :) = normalize(sig(i, :),'range',[0 1]);
    end
    plot((sigt + (1: size(sigt, 1))')')
else
    plot((sig + (1: size(sig, 1))')')
end

axis tight
axis square
title('Traces')
end
