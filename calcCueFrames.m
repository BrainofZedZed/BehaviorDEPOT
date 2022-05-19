% calcCueFrames:  converts the timestamps of experimental events (saved in
% ts structure) to video frames based on video start time, saved with
% a 'YYYY-MM-DD-HHMMSS' string in the title (automatically done with
% PointGrey cameras) or manually inputted
% Working directory MUST contain 1 movie file (.avi or .mp4) and one .mat
% file (Fear Conditioning experiment data containing 'ts' timestamp struct)
% INPUT:  (optional, double) fps. If omitted, will load video and pull FPS info
% from vid; (optional, char) dt, datetime of video start in 'YYYY-MM-DD-HHMMSS' 
% format. If omitted, will look pull from video name
% OUTPUT: saves CS+, CS-, US, and LASER cue frames (which ever is applicable) 
% in N (events) x 2 ([on, off]) matrix as seperate .csv files, as well as a
% 'cueframes.mat' file containing all the info

% TIPS ON HOW TO USE
% 1) save this as a path fxn
% 2) have data organized into folders with PG video and experiment file in
% same folder. Make a folder the working directory
% 3) call this function (if fps is known, can provide argument, eg
% calcCueFrames(50)

function calcCueFrames(fps, dt)

% load experiment data
data = dir('*.mat');
load([data.folder '\' data.name]);

% get name of vid file
vid = dir('*.avi');
if isempty(vid)
    vid = dir('*.mp4');
end

% load vid file and get frame rate if not inputted
if ~exist('fps','var')
    thisvid = VideoReader([vid.folder '\' vid.name])';
    fps = thisvid.framerate;
end

% get start time from vid title if not inputted
if ~exist('dt','var')
    dt = regexp(vid.name,'....-..-..-......');
    dt = vid.name(dt:dt+16);
else
    dt = char(dt);
end

% format start time
d1 = string(dt(1:4));
d2 = string(dt(6:7));
d3 = string(dt(9:10));
d4 = string(dt(12:13));
d5 = string(dt(14:15));
d6 = string(dt(16:17));
vid0 = [d1, d2, d3, d4, d5, d6];

%% convert timestamps to video frames
% four possible timestamps:  csp, csm, us, laser
% do csp
if ~isempty(ts.csp_on)
    csp_frames = zeros(size(ts.csp_on,1),2);
    for i = 1:size(ts.csp_on,1)
        csp_frames(i,1) = calcDifSeconds(vid0,ts.csp_on(i,:));
        csp_frames(i,2) = calcDifSeconds(vid0,ts.csp_off(i,:));
    end
    
    % convert dif in seconds to dif in frames
    % rounding is required to make matrix same size. May introduce marginal
    % (1 frame) offest errors.
    csp_frames = csp_frames * fps;
    csp_frames = round(csp_frames);
    meandif = round(mean(csp_frames(:,2) - csp_frames(:,1)));
    csp_frames = [csp_frames(:,1), csp_frames(:,1)+meandif];
    writematrix(csp_frames, 'csp_cue_frames.csv');
    disp('converted CS+ times to video frames and saved as csv');
    cueframes.csp = csp_frames;
end

% do csm
if ~isempty(ts.csm_on)
    csm_frames = zeros(size(ts.csm_on,1),2);
    for i = 1:size(ts.csm_on,1)
        csm_frames(i,1) = calcDifSeconds(vid0,ts.csm_on(i,:));
        csm_frames(i,2) = calcDifSeconds(vid0,ts.csm_off(i,:));
    end
    
    % convert dif in seconds to dif in frames
    csm_frames = csm_frames * fps;
    csm_frames = round(csm_frames);
    meandif = round(mean(csm_frames(:,2) - csm_frames(:,1)));
    csm_frames = [csm_frames(:,1), csm_frames(:,1)+meandif];
    writematrix(csm_frames, 'csm_cue_frames.csv');
    disp('converted CS- times to video frames and saved as csv');
    cueframes.csm = csm_frames;
end

% do us
if ~isempty(ts.us_on)
    us_frames = zeros(size(ts.us_on,1),2);
    for i = 1:size(ts.us_on,1)
        us_frames(i,1) = calcDifSeconds(vid0,ts.us_on(i,:));
        us_frames(i,2) = calcDifSeconds(vid0,ts.us_off(i,:));
    end
    
    % convert dif in seconds to dif in frames
    us_frames = us_frames * fps;
    us_frames = round(us_frames);
    meandif = round(mean(us_frames(:,2) - us_frames(:,1)));
    us_frames = [us_frames(:,1), us_frames(:,1)+meandif];
    writematrix(us_frames, 'us_cue_frames.csv');
    disp('converted US times to video frames and saved as csv');
    cueframes.us = us_frames;
end

% do laser
if ~isempty(ts.laser_on)
    laser_frames = zeros(size(ts.laser_on,1),2);
    for i = 1:size(ts.laser_on,1)
        laser_frames(i,1) = calcDifSeconds(vid0,ts.laser_on(i,:));
        laser_frames(i,2) = calcDifSeconds(vid0,ts.laser_off(i,:));
    end
    
    % convert dif in seconds to dif in frames
    laser_frames = laser_frames * fps;
    laser_frames = round(laser_frames);
    meandif = round(mean(laser_frames(:,2) - laser_frames(:,1)));
    laser_frames = [laser_frames(:,1), laser_frames(:,1)+meandif];
    writematrix(laser_frames, 'laser_cue_frames.csv');
    disp('converted laser times to video frames and saved as csv');
    cueframes.laser = laser_frames;
end

save([data.folder '\' data.name],'cueframes', '-append');
disp('appended cueframes into "cueframes" struct in .mat file');

end