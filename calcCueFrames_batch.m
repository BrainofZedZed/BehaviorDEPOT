%% Params
doCSV = 0;  % 0 or 1, save to csv
fps = 50; % load fps, leave blank to autoload

%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
P.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
P.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
P.video_folder_list = prepBatch(string(P.video_directory)); %Generate list of videos to analyze


for j = 1:length(P.video_folder_list)
    % Initialize 
    current_video = P.video_folder_list(j);    
    video_folder = strcat(P.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
%%
% assume save to CSV unless indicated otherwise
if ~exist('doCSV','var')
    doCSV = 1;
end

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
    if doCSV
        writematrix(csp_frames, 'csp_cue_frames.csv');
    end
    disp('converted CS+ times to video frames and saved as csv');
    cueframes.CSp = csp_frames;
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
    if doCSV
        writematrix(csm_frames, 'csm_cue_frames.csv');
    end
        disp('converted CS- times to video frames and saved as csv');
    cueframes.CSm = csm_frames;
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
    if doCSV
        writematrix(us_frames, 'us_cue_frames.csv');
    end
    disp('converted US times to video frames and saved as csv');
    cueframes.US = us_frames;
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
    if doCSV
        writematrix(laser_frames, 'laser_cue_frames.csv');
    end
    disp('converted laser times to video frames and saved as csv');
    cueframes.laser = laser_frames;
end

save([data.folder '\' data.name],'cueframes', '-append');
disp('appended cueframes into "cueframes" struct in .mat file');
disp(['for ' pwd]);

clearvars -except doCSV fps  P j;
    
end

function video_folder_list = prepBatch(video_directory)
    cd(video_directory)
    directory_contents = dir;
    directory_contents(1:2) = [];
    ii = 0;

    for i = 1:size(directory_contents, 1)
        current_structure = directory_contents(i);
        if current_structure.isdir
            ii = ii + 1;
            video_folder_list(ii) = string(current_structure.name);
            disp([num2str(i) ' directory loaded'])
        end
    end
end

%% supporting fxn


function dif = calcDifSeconds(start, fin)
% calcDifSeconds:  calculates difference in seconds between two vector date
% inputs. 
% INPUT: t1 - start time; t2 - end time. Both input as [YYYY MM DD HH MM
% SS]. t2 can be vector or vector array
% OUTPUT: dif - difference between two timepoints in seconds
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
