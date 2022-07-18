function nts2nirs_batch(nts_folder,sd_filename,answer)
if ~exist('nts_folder','var')
    nts_folder = string(uigetdir('Select NTS data folder...'));
end
if ~exist('sd_filename','var')
    [sd_filename, sd_pathname] = uigetfile('*','Select associated SD file...');
else
    sd_pathname = '';
end
if ~exist('answer','var')
    prompt = {'Enter total number of physical sources (of both wavelengths):','Enter number of detectors:', 'Enter spatial unit of array layout (mm or cm):', 'Enter number of event marker columns in output data'};
    dlg_title = 'Source, Detectorand Event Columns Numbers';
    num_lines = 1;
    def = {'32','16','mm','3'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    nsrc = str2num(answer{1});
    ndet = str2num(answer{2});
    spat_unit = answer{3};
    nevent_cols = str2num(answer{4});
else
    nsrc = str2num(answer{1});
    ndet = str2num(answer{2});
    spat_unit = answer{3};
    nevent_cols = str2num(answer{4});
end

nts_files = arrayfun(@(x)string(x.name),dir(strcat(nts_folder, "/*.txt")));


parfor f = 1:size(nts_files,1)
    nts_filename = char(strcat(nts_folder , "/", nts_files(f)));
    nts2nirs(nts_filename, sd_filename, nsrc, ndet, spat_unit, nevent_cols)
end