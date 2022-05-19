
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
data = dir('*-*-*_*-*-*.mat');
load([data.folder '\' data.name]);

% load JSON file
msdata = read_json('metaData.json');
t = msdata.recordingStartTime;

% load frame lookup with timestamps
load('frtslu.mat');

% format start time
vid0 = [t.year, t.month, t.day, t.hour, t.minute, (t.second + (t.msec/1000))];
cuetimes.msStartTime = vid0;
%% convert timestamps to video frames
% four possible timestamps:  csp, csm, us, laser
% do csp
if ~isempty(ts.csp_on)
    csp_frames = zeros(size(ts.csp_on,1),2);
    for i = 1:size(ts.csp_on,1)
        csp_frames(i,1) = calcDifSeconds(vid0,ts.csp_on(i,:));
        csp_frames(i,2) = calcDifSeconds(vid0,ts.csp_off(i,:));
    end
    cuetimes.csp = csp_frames;
    
    % convert dif in seconds to dif in frames
    cspms = cuetimes.csp * 1000;
    match = zeros(size(cspms));
    for f = 1:size(cspms,1)
        t = cspms(f,1);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,1) = ind;
         
        t = cspms(f,2);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,2) = ind;
    end
    cueframes.csp = match;
    
    % for alignment. may introduce rounding error of 1 frame at offest
    meandif = round(mean(cueframes.csp(:,2) - cueframes.csp(:,1)));
    cueframes.csp = [cueframes.csp(:,1), cueframes.csp(:,1)+meandif];
end

% do csm
if ~isempty(ts.csm_on)
    csm_frames = zeros(size(ts.csm_on,1),2);
    for i = 1:size(ts.csm_on,1)
        csm_frames(i,1) = calcDifSeconds(vid0,ts.csm_on(i,:));
        csm_frames(i,2) = calcDifSeconds(vid0,ts.csm_off(i,:));
    end
    cuetimes.csm = csm_frames;
    
    % convert dif in seconds to dif in frames
    csmms = cuetimes.csm * 1000;
    match = zeros(size(csmms));
    for f = 1:size(csmms,1)
        t = csmms(f,1);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,1) = ind;
         
        t = csmms(f,2);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,2) = ind;
    end
    cueframes.csm = match;
    
    % for alignment. may introduce rounding error of 1 frame at offest
    meandif = round(mean(cueframes.csm(:,2) - cueframes.csm(:,1)));
    cueframes.csm = [cueframes.csm(:,1), cueframes.csm(:,1)+meandif];

end

% do us
if ~isempty(ts.us_on)
    us_frames = zeros(size(ts.us_on,1),2);
    for i = 1:size(ts.us_on,1)
        us_frames(i,1) = calcDifSeconds(vid0,ts.us_on(i,:));
        us_frames(i,2) = calcDifSeconds(vid0,ts.us_off(i,:));
    end
    cuetimes.us = us_frames;
    
    % convert dif in seconds to dif in frames

    usms = cuetimes.us * 1000;
    match = zeros(size(usms));
    for f = 1:size(usms,1)
        t = usms(f,1);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,1) = ind;
         
        t = usms(f,2);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,2) = ind;
    end
    cueframes.us = match;
    
    % for alignment. may introduce rounding error of 1 frame at offest
    meandif = round(mean(cueframes.us(:,2) - cueframes.us(:,1)));
    cueframes.us = [cueframes.us(:,1), cueframes.us(:,1)+meandif];


end

% do laser
if ~isempty(ts.laser_on)
    laser_frames = zeros(size(ts.laser_on,1),2);
    for i = 1:size(ts.laser_on,1)
        laser_frames(i,1) = calcDifSeconds(vid0,ts.laser_on(i,:));
        laser_frames(i,2) = calcDifSeconds(vid0,ts.laser_off(i,:));
    end
    cuetimes.laser = laser_frames;
    % convert dif in seconds to dif in frames
    laserms = cuetimes.laser * 1000;
    match = zeros(size(laserms));
    for f = 1:size(laserms,1)
        t = laserms(f,1);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,1) = ind;
         
        t = laserms(f,2);
        [~,ind] = min(abs(frtslu(:,1) - t));
         match(f,2) = ind;
    end
    cueframes.laser = match;
    
    % for alignment. may introduce rounding error of 1 frame at offest
    meandif = round(mean(cueframes.laser(:,2) - cueframes.laser(:,1)));
    cueframes.laser = [cueframes.laser(:,1), cueframes.laser(:,1)+meandif];

end

save([data.folder '\' data.name],'cuetimes', 'cueframes', '-append');
save('cueframes.mat','cueframes');
disp('appended cueframes and cuetimes struct in .mat file');
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
