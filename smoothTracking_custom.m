%smoothTracking

%INPUT: Tracking, Params
%OUTPUT: Tracking

%FUNCTION: apply 2djumpsmooth to data from Tracking

function Tracking = smoothTracking_custom(Tracking, Params)
    % Smooth Data with 2DJumpsmooth (Boxcar Smoothing)
    %time = time stamps of position data
    %ux, uy = position data
    
    gapThreshold = Params.Smoothing.gapThreshold;
    jumpThreshold = Params.Smoothing.jumpThreshold;
    nanRadius = Params.Smoothing.nanRadius;
    boxWidth = Params.Smoothing.boxWidth;
    part_names = Params.part_names;
    
    for i = 1:length(part_names)  
        i_part = part_names{i};
        time = (1:size(Tracking.(i_part),2))';
        ux = Tracking.(i_part)(1,:)';
        uy = Tracking.(i_part)(2,:)';
        %% new outlier cutoff section
        d = zeros(1,length(ux)-1);
        for i = 1:length(ux)-1
            d(i) = pdist([ux(i), uy(i);ux(i+1), uy(i+1)]);
        end
        d(d>2*std(d,'omitnan')) = nan;
        ux(isnan(d)) = nan;
        uy(isnan(d)) = nan;
        
        for i = 1:length(ux)-1
            d(i) = pdist([ux(i), uy(i);ux(i+1), uy(i+1)]);
        end
        d(d>3*std(d,'omitnan')) = nan;
        ux(isnan(d)) = nan;
        uy(isnan(d)) = nan;
        %%

        [x,y] = jumpsmooth2D(time, ux, uy, gapThreshold, jumpThreshold, nanRadius, boxWidth);
        Tracking.Smooth.(i_part) = [x,y]';
        
        % find NaNs that remain after smoothing and interpolate missing
        % data
        Tracking.Smooth.(i_part)(1,:) = fillmissing(Tracking.Smooth.(i_part)(1,:), 'spline');
        Tracking.Smooth.(i_part)(2,:) = fillmissing(Tracking.Smooth.(i_part)(2,:), 'spline');
    end

    disp('Data smoothed and stored in Tracking.Smooth');
end