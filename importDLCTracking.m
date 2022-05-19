%importDLCTracking

%INPUT: P (batch parameter structure)
%OUTPUT: data (generic variable containing imported DLC data)
%FUNCTION: import DLC CSV/H5 file  

function [data, Params] = importDLCTracking(Params)
    data = [];
    cd(Params.basedir);
    disp('Reading tracking file')
    % Select CSV/H5 file and Extract 
    if strcmpi(Params.tracking_fileType, 'csv')
        if isfield(Params,'tracking_file')
            M = readmatrix(Params.tracking_file);
            data = M';
            [~,M2] = xlsread(Params.tracking_file);
            S = dir('*.csv');

        else
            S = dir('*shuffle*.csv');
            if length(S) > 1  % differentiate cue and tracking csv files
                if contains(S(1).name, 'cue')
                    trackfile = 2;
                    Params.cueFile = [S(1).folder '\' S(1).name];
                elseif contains(S(2).name, 'cue')
                    trackfile = 1;
                    Params.cueFile = [S(2).folder '\' S(2).name];
                else
                    disp('Error. Too many .csv files in the folder. Folder should only contain tracking .csv file, and optionally a .csv file for cues');
                end
            else
                trackfile = 1;
            end
            M = readmatrix(S(trackfile).name);
            data = M';
            [~,M2] = xlsread(S(trackfile).name);
        end
        part_names = M2(2,2:3:end);
        disp('CSV Loaded');
    elseif strcmpi(Params.tracking_fileType, 'h5' | 'H5')
        if isfield(Params,'tracking_file')
            dataAdd = h5read(Params.tracking_file, '/df_with_missing/table');
            dataAddMat = dataAdd.values_block_0(:,:);
        else
            S = dir('*.h5'); 
            %List folder contents of .h5 file and assign to S; important to make sure only one .h5 is in current folder
            dataAdd = h5read(S(1).name,'/df_with_missing/table');
            dataAddMat = dataAdd.values_block_0(:,:);
        end
        %Copy all x,y, and p values for each tracked body part
        data = [data, dataAddMat];
        %Store all tracking info in data
        disp('H5 Loaded');
    end
    
    % remove characters from names that may break the code
    part_names = cleanText(part_names);
    Params.part_names = part_names;
    disp('Tracking file loaded for')
    disp(S(1).name)
    
end
