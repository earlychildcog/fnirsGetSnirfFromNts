function nts2nirs(nts_filename, sd_filename, nsrc, ndet, spat_unit, nevent_cols)

%This function takes the universal output format .txt file from NTS
%systems and converts it to .nirs format so as to be compatible with
%HOMER2. 

%########################### INPUTS #######################################:

%nts_filename:  The full path name of the .txt NTS output data

%sd_filename:   The full path name of the .SD homer layout file which match
                %the array used to record the data with the NTS
                
%nsrc:          The number of physical sources in your NTS system (default
                %32).  Note that the number of sources is 
                %NOT the same as the number of source POSITIONS in the SD 
                %file.  Each source position (and optical fibre) is 
                %attached to a PAIR of laser diodes (usually with one at 
                %770nm and one at 850nm).  The number of sources requested 
                %by this script is the TOTAL number of 
                %PHYSICAL sources = 2 x the number of source positions.
                
%ndet:          The number of detectors in the system (default 16)

%nevent_cols:   The number of event marker columns in your NTS data file.
                %For NTS software version 2.8 or later, this is 3.  For
                %earlier versions (e.g. Manchester system) it is 1.

%########################### OUTPUTS #####################################:

%A .nirs file with the same name and location as the original .txt data.

%#########################################################################
%RJC November 2013 robert.cooper@ucl.ac.uk
%University College London

%CHANGE LOG
%RJC UPDATED DECEMBER 2013 to correct error observed by Manchester group.
%RJC UPDATED February 2014 to improve system compatability and force initial timepoint to zero.
%RJC UPDATED May 2014.
%RJC UPDATED 02 Oct 2014 to improve compatibility with different event column numbers.
%RJC UPDATED 06 May 2015 added spat_unit to command line function inputs.
%RJC UPDATED 27 July 2015 use 32 instead of nsrc to dictate column numbers (line 73)
%RJC UPDATED 29 Oct 2015 to use size instead of length when assessing MeasList.

if ~exist('nts_filename','var');
    [nts_filename, nts_pathname] = uigetfile('*.txt','Select NTS data text file...');
else
    nts_pathname = '';
end
if ~exist('sd_filename','var');
    [sd_filename, sd_pathname] = uigetfile('*','Select associated SD file...');
else
    sd_pathname = '';
end
if ~exist('nsrc','var');
    prompt = {'Enter total number of physical sources (of both wavelengths):','Enter number of detectors:', 'Enter spatial unit of array layout (mm or cm):', 'Enter number of event marker columns in output data'};
    dlg_title = 'Source, Detectorand Event Columns Numbers';
    num_lines = 1;
    def = {'32','16','mm','3'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    nsrc = str2num(answer{1});
    ndet = str2num(answer{2});
    spat_unit = answer{3};
    nevent_cols = str2num(answer{4});
end

%load NTS data using textscan to account for event ascii
% h1 = msgbox('Converting NTS data to .nirs format ...');

%arrange padding colums (time and events)
width_pad = nevent_cols + 1;

%There are always 32 columns.
formatspec = ['%f ' repmat('%s ',1,nevent_cols) repmat('%f ',1,32)];

fid = fopen([nts_pathname nts_filename]);
all_txt = textscan(fid,formatspec,'delimiter','\t,');
fclose(fid);

%find length of each column and select minimum (as column lengths appear to vary...)
l_all = cellfun(@length,all_txt);
lall = min(l_all);

%crop out nts data (ignore event and time columns)
for src = 1:nsrc;
    tmp = cell2mat(all_txt(src + width_pad));
    nts_all(:,src) = tmp(1:lall);
end

%load SD file 
load(strcat(sd_pathname,sd_filename),'-mat');
lml = size(SD.MeasList,1);
ml = SD.MeasList;

%########################################
%crop out data, time and event column(s)
t_all = cell2mat(all_txt(1));

%correct time so first point = 0;
t_all = t_all - t_all(1);
%t_all = [0:1:(length(t_all) - 1)]/10;
maxTime = length(t_all)/ndet/10 - 0.1;
t = [0:0.1:maxTime]';

if nevent_cols == 1;
    events_all = all_txt{2};
    for j = 1:lml/2;
        for i = 1:floor(lall/ndet);
            det = SD.MeasList(j,2);
            src = SD.MeasList(j,1);
            columnW1 = 1+(src-1)*2;
            columnW2 = columnW1 + 1;
            
            d(i,j) = nts_all(det + ndet*(i-1),columnW1);
            d(i,j+lml/2) = nts_all(det + ndet*(i-1),columnW2);
            
            s_tmp_col{1}(i,1) = events_all(1 + ndet*(i-1));
        end
    end
end

if nevent_cols == 3;
    events_all.C1 = all_txt{2};
    events_all.C2 = all_txt{3};
    events_all.C3 = all_txt{4};
    
    for j = 1:lml/2;
        for i = 1:floor(lall/ndet);
            det = SD.MeasList(j,2);
            src = SD.MeasList(j,1);
            columnW1 = 1+(src-1)*2;
            columnW2 = columnW1 + 1;
            
            d(i,j) = nts_all(det + ndet*(i-1),columnW1);
            d(i,j+lml/2) = nts_all(det + ndet*(i-1),columnW2);
            
            s_tmp_col{1}(i,1) = events_all.C1(1 + ndet*(i-1));
            s_tmp_col{2}(i,1) = events_all.C2(1 + ndet*(i-1));
            s_tmp_col{3}(i,1) = events_all.C3(1 + ndet*(i-1));
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following code FORMATs the S-vector for different circumstances: either trigger is numerical
% consecutive, numerical non-consecutive or contains strings. In the
% latter two cases, we treat each event ascii character as a stimulus
% 'type'- it gets it's own column in s.

count = 1;
s_all = [];
for i = 1:nevent_cols;
    
    s_tmp = s_tmp_col{i};
    
    [uni, ~, uni_index] = unique(s_tmp);
    str_flag = 0;
    
    if length(uni) == 1; %Is event column empty or continuous? If so do nothing.
        s = zeros(length(s_tmp),1);
    else
        
        %Is event column numerical only?
        [s_tmp_num,str_flag] = str2num(char(s_tmp));
        
        if str_flag == 1; %Numerical only!
            %Are numbers consecutive (Manually Triggering) or are there only 2 cases (on/off)?
            difftypes = unique(diff(s_tmp_num));
            if (length(difftypes) == 2 && max(abs(difftypes)) == 1) || length(uni) == 2;
                s = zeros(length(s_tmp_num),1);
                s(diff(s_tmp_num)>0) = 1;
            else %Numbers not consecutive and there are more than 2 types so sort column-wise. Ignore zeros.
                s = zeros(length(s_tmp_num),length(uni)-1);
                for j = 1:length(uni)-1;
                    s_tmp2 = zeros(length(s_tmp_num),1);
                    ind = find(uni_index == j+1);
                    s_tmp2(ind) = 1;
                    s(diff(s_tmp2)>0,j) = 1;
                    CondNames{count} = uni{j+1};
                    count = count+1;
                end
            end
            
        else %(str_flag == 0)-- Strings!
            s = zeros(length(s_tmp),length(uni)-1);
            for j = 1:length(uni)-1;
                s_tmp2 = zeros(length(s_tmp),1);
                ind = find(uni_index == j+1);
                s_tmp2(ind) = 1;
                s(:,j) = s_tmp2;
                CondNames{count} = uni{j+1};
                count = count+1;
            end
        end;
    end

    s_all = [s_all s];
end

%This is tricky because there can be multiple conditions in each event
%marker column and multiple columns.  Also, we want zero columns to be
%removed, except one!
ind = sum(s_all)>0;
if ~ind
    s = zeros(size(d,1),1); %If all columns are empty, populate vector of zeros
else
    s = s_all(:,ind);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Populate additional variables for .nirs format
aux = zeros(size(d,1),8);

if strcmpi(spat_unit,'mm');
    SD.SpatialUnit = 'mm';
elseif ~strcmpi(spat_unit,'cm');
    SD.SpatialUnit = 'cm';
else
    error('ERROR: Spatial unit not recognised');
end
        
%Output data to .nirs file;
namestr = [nts_pathname nts_filename(1:end-4)];
outname = [namestr '.nirs'];
fprintf('Saving %s ...\n',outname);
if exist('CondNames','var');
    save(outname,'SD','aux','d','s','t','CondNames');
else
    save(outname,'SD','aux','d','s','t');
end

% msgbox({['Conversion complete! Data file saved as: '] outname});
