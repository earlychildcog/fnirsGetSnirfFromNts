function generate_nirs_events(nirs_folder,varnames,timejump,hrlag_default)

%function to generate nirs events out of markers in the output file.

if ~exist('nirs_folder','var')
    nirs_folder = uigetdir('Select NTS data folder...');
end


nts_files = arrayfun(@(x)string(x.name), dir(strcat(nirs_folder,"/*.nirs")));

%change in the future to loot into time array
fs = 10;            %recording frequency
if ~exist('hrlag_default','var') || isempty(hrlag_default)
    hrlag_default = 6;          %lag of haemodynamic response in infants
end
%select variables to move
if ~exist('varnames','var') || isempty(varnames)
    varall = [""];
    for f = 1:size(nts_files,2)
        nirs_filename = strcat(nirs_folder,"/",nts_files(f));
        nirsdata = load(nirs_filename,'-mat');
        varall = union(varall,string(nirsdata.CondNames));
    end
    varall = setdiff(varall,"");
    [indx,tf] = listdlg('ListString',varall);
    varnames = varall(indx);
    if ~tf
        return
    end
end


%select where to move
if ~exist('timejump','var') || isempty(timejump)
    prompt      = {'Enter when selected markers should be moved' 'Hemodynamic delay'};
    dlgtitle    = 'Time shifting from old timestamp';
    answers     = cellfun(@str2double,inputdlg(prompt,dlgtitle,1,{'' num2str(hrlag_default)}));
    timejump    = answers(1);
    hrlag       = answers(2);
else
    hrlag = hrlag_default;
end

%create subfolder to save the new .nirs files in
subfolder = sprintf("%s/%s%d",nirs_folder,varnames,timejump);
mkdir(subfolder);
for f = 1:size(nts_files,1)
    nirs_filename = strcat(nirs_folder,"/",nts_files(f));
    nirsdata = load(nirs_filename,'-mat');
    fprintf('opening %s\n',nirs_filename);
    varall = string(nirsdata.CondNames);
    indx    = find(cellfun(@(x)~isempty(x),regexp(varall,['[' sprintf('%s',varnames(:)) ']'])));
    vardata = nirsdata.s;
    for var = indx
        new_pos                 = find(vardata(:,var)) + timejump*fs + hrlag*fs;
        vardata(:,var)          = zeros(size(vardata(:,var)));
        
        if any(new_pos <= 0)
            warning('Lost %d markers in %s\n',sum(new_pos <= 0),nirs_filename);
            new_pos = new_pos(new_pos > 0);
            
            if ~isempty(new_pos)
                vardata(new_pos,var)    = 1;
            end
        else
            vardata(new_pos,var)    = 1;
        end
    end
    nirsdata.s = vardata(:,indx);
    nirsdata.CondNames = nirsdata.CondNames(indx);
    %copyfile(nirs_filename, [nirs_filename '.bak'])
    parsave(strcat(subfolder, "/", strrep(nts_files(f),".nirs","_editted.nirs")),nirsdata);
end
end







