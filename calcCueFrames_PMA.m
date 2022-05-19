function calcCueFrames_PMA()
% goal:  take timestamps and make them into cue files
% works for avi and mp4 vids

%function outfile ts2cue(indir)
% load experiment data
data = dir('*.mat');
load([data.folder '\' data.name]);

% get name of vid file
vid = dir('*.avi');
if isempty(vid)
    vid = dir('*.mp4');
end

% load vid file and get frame rate
thisvid = VideoReader([vid.folder '\' vid.name])';
fps = thisvid.framerate;


dt = regexp(vid.name,'....-..-..-......');
dt = vid.name(dt:dt+16);
d1 = string(dt(1:4));
d2 = string(dt(6:7));
d3 = string(dt(9:10));
d4 = string(dt(12:13));
d5 = string(dt(14:15));
d6 = string(dt(16:17));
vid0 = [d1, d2, d3, d4, d5, d6];

%% convert tone timestamps ("Tone1" as CS+) to video frames
% find time dif for CS+ and convert to frames
tone_frames = zeros(size(ts.csp_on,1),2);
for i = 1:size(ts.csp_on,1)
    tone_frames(i,1) = calcDifSeconds(vid0,ts.csp_on(i,:));
    tone_frames(i,2) = calcDifSeconds(vid0,ts.csp_off(i,:));
end
% convert dif in seconds to dif in frames
tone_frames = tone_frames * fps;
tone_frames = round(tone_frames);
meandif = round(mean(tone_frames(:,2) - tone_frames(:,1)));
tone_frames = [tone_frames(:,1), tone_frames(:,1)+meandif];
writematrix(tone_frames, 'tone_cue_frames.csv');
disp('converted tone times to video frames and saved as csv');

%% convert shock timestamps
% find time dif for US and convert to frames
if ~isempty(ts.us_on)
    us_frames = zeros(size(ts.us_on,1),2);
    for i = 1:size(ts.us_on,1)
        us_frames(i,1) = calcDifSeconds(vid0,ts.us_on(i,:));
        us_frames(i,2) = calcDifSeconds(vid0,ts.us_off(i,:));
    end
    us_frames = us_frames * fps;
    us_frames = round(us_frames);
    writematrix(us_frames,'shock_cue_frames.csv');
    disp('converted shock times to video frames and saved as csv');

else
    us_frames = [];
    disp('shock timestamps not found');
end

end