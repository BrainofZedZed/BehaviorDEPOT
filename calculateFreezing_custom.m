%calculateFreezing

%INPUT: Metrics structure
%OUTPUT: Behavior.Freezing structure

%FUNCTION: calculate the freezing frames via transformation of data from
%the Metrics structure and save into Behavior structure

% Future: Calculate average velocity of body; test in place of
% RearBackVelocity

function Freezing = calculateFreezing_custom(Metrics, Params)    

numframes = length(Metrics.Location);
% choose which freezing detector to use based on frame rate
% under 40 fps uses jitter; above 40 uses velocity

if Params.Video.frameRate < 40
    try
        bp_list = [Metrics.Velocity.Head; Metrics.Velocity.Nose; Metrics.Velocity.Tailbase]';
    catch
        error('Cannot classify freezing. Standard FPS (< 40 FPS) freezing classifier requires Nose, Tailbase, and Head (or Ears) to be tracked');
    end
    
    
     % apply jitter threshold
     % find points at which the mean of the data changes most significantly
     % MinThreshold = minimum residual error improvement
    changethresh = 10*(1/Params.Freezing.sensitivityGain);
    for bp = 1:3
        test = bp_list(:,bp);        
        %ipt = findchangepts(test,'statistic','mean','MinThreshold',100000); 
        ipt = findchangepts(test,'statistic','mean','MinThreshold',changethresh); 
        dipt = diff(ipt);
        consider = find(dipt > (Params.Freezing.minDuration * Params.Video.frameRate)); % identify frames where jitter is stable for more than 1sec 
        for cc = 1:length(consider)
            considerpt = consider(cc);
            long_start(cc) = ipt(considerpt);
            long_end(cc) = ipt(considerpt+1);
        end
            for tt = 1:length(consider)
                bites(tt) = mean(test(long_start(tt):long_end(tt)));
            end
        if ~isempty(bites)
            jitter(bp) = std(bites)*1 + mean(bites) * 0.75; % threshold per body point 
        else
            jitter(bp) = 0;
        end
    end
    
    freeze = bp_list(:,1) < jitter(1) & ...
    bp_list(:,2) < jitter(2) & ...
    bp_list(:,3) < jitter(3) & ...
    abs(Metrics.Diff.HeadAngle)' < (Params.Freezing.angleThreshold); % freezing == 1, no freezing == 0
    
    % Mark freezing
    f_start = strfind(freeze', [0 1]) + 1;
    f_end = strfind(freeze', [1 0]);
    
    % set minimum duration of freezing bout (1 second)
    for ff = 1:length(f_start)
        if f_end(ff) - f_start(ff) < Params.Video.frameRate 
            freeze(f_start(ff):f_end(ff)) = 0;
        end
    end
    
    withinFreezingThreshold = freeze;


else
    try
        try
            % Velocity based freezing detector
            withinFreezingThreshold = (nanmean([Metrics.Velocity.Head;Metrics.Velocity.RearBack])' < Params.Freezing.velocityThreshold) & (abs(Metrics.Diff.HeadAngle(:)) < Params.Freezing.angleThreshold);
        catch
            withinFreezingThreshold = (nanmean([Metrics.Velocity.Head;Metrics.Velocity.Tailbase])' < Params.Freezing.velocityThreshold) & (abs(Metrics.Diff.HeadAngle(:)) < Params.Freezing.angleThreshold);
        end
    catch
        disp('Error with freezing classifer. High FPS videos (> 40 FPS) require Head (or Ears + Nose) and Legs (or Tailbase or RearBack) to be tracked');
    end
end 


    % convolve individual bouts to smooth over falsely non-contiguous
    % freezing bout detections
    freeze_counts = conv(withinFreezingThreshold, ones(1, Params.Freezing.windowWidth), 'same');
    freezingInds = freeze_counts >= Params.Freezing.countThreshold;
    freezingInds_end = freeze_counts >= round(Params.Freezing.countThreshold/2);
    freezingInds_end(1:round(numframes-1.8*Params.Freezing.windowWidth)) = 0;
    freezingInds = freezingInds | freezingInds_end;

   % set first and last frame to not freezing
    freezingInds(length(freezingInds)) = 0;
    freezingInds(1) = 0; 
    
    % find freeze start and end indices
    freezingDiff = diff(freezingInds);
    freezingDiffInds = find(freezingDiff);


    freezeStart = zeros(1, round(length(freezingDiffInds)/2));
    freezeEnd = zeros(1, round(length(freezingDiffInds)/2));

    jj = 1; kk = 1;
    for i=1:length(freezingDiffInds)
        if freezingDiff(freezingDiffInds(i)) == 1
            freezeStart(jj) = freezingDiffInds(i);
            jj = jj+1;
        elseif freezingDiff(freezingDiffInds(i)) == -1
            freezeEnd(kk) = freezingDiffInds(i);
            kk = kk+1;
        end
    end

    % Adjust minimum freezing duration
    % LOOK HERE FOR POOR 
    if exist('freezeStart', 'var')
        if length(freezeStart) > length(freezeEnd)
            freezeStart = freezeStart(1:end-1);
        end
      for i = 1:length(freezeStart)
         if freezeEnd(i) - freezeStart(i) < round(Params.Video.frameRate .* Params.Freezing.minDuration) %set the minimum duration here
             freezingInds(freezeStart(i):freezeEnd(i)) = 0;
             freezeStart(i) = NaN; freezeEnd(i) = NaN;
         end
      end
    end

    freeze_inds_to_delete = find(isnan(freezeStart));
    freezeStart(freeze_inds_to_delete) = [];
    freezeEnd(freeze_inds_to_delete) = [];

    Freezing.Bouts = [];

    for i = 1:length(freezeStart)
    Freezing.Bouts(i, 1) = freezeStart(i);
    Freezing.Bouts(i, 2) = freezeEnd(i);
    end

    Freezing.Count = size(Freezing.Bouts,1);
    Freezing.Length = freezeEnd - freezeStart;
    Freezing.Vector = zeros(numframes, 1);

    %Binarized vector of freezing
    for i = 1:size(Freezing.Bouts,1)
        Freezing.Vector(Freezing.Bouts(i,1):Freezing.Bouts(i,2)) = 1;
    end

end