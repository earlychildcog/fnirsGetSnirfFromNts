function cleanup_events(nirs_folder,exclfile)

%function to generate nirs events out of markers in the output file.
% badevents is a subjN x 2 cell array, with each cell containing the events that need to be removed
if ~exist('nirs_folder','var')
    nirs_folder = uigetdir('Select .nirs data folder...');
end


nts_files = arrayfun(@(x)string(x.name), dir(strcat(nirs_folder,"/*.nirs")));
block1s = nts_files(contains(nts_files,'block1'));
block2s = nts_files(contains(nts_files,'block2'));
subjNames1 = arrayfun(@(x)str2num(extractBefore(x,4)),block1s);
subjNames2 = arrayfun(@(x)str2num(extractBefore(x,4)),block2s);
if ~exist('exclfile','var')
    exclfile = uigetfile('Select .nirs data folder...');
end

opts = detectImportOptions(exclfile);
opts = setvartype(opts, opts.SelectedVariableNames, 'char');  %or 'char' if you prefer
T = readtable(exclfile, opts);
T(:,contains(T.Properties.VariableNames,'Age')) = [];
T(:,contains(T.Properties.VariableNames,'omment')) = [];
% block1 = table2array(T(ismember(T.ParticipantNr,subjNames1),7:14)) == 1;
% block2 = table2array(T(ismember(T.ParticipantNr,subjNames2),15:22)) == 1;
blockData{1} = ones(sum(ismember(cellfun(@str2num,T.ParticipantNr),subjNames1)), 8);
blockData{2} = ones(sum(ismember(cellfun(@str2num,T.ParticipantNr),subjNames2)), 8);

T.Bl1TrialsExcluded = cellfun(@(x)strrep(x,'0',''),T.Bl1TrialsExcluded,'UniformOutput',false);
T.Bl2TrialsExcluded = cellfun(@(x)strrep(x,'0',''),T.Bl2TrialsExcluded,'UniformOutput',false);



bt{1} = cellfun(@str2num,T.Bl1TrialsExcluded(ismember(cellfun(@str2num,T.ParticipantNr),subjNames1)),'UniformOutput',false);
bt{2} = cellfun(@str2num,T.Bl2TrialsExcluded(ismember(cellfun(@str2num,T.ParticipantNr),subjNames2)),'UniformOutput',false);
ft{1} = cellfun(@str2num,T.Bl1FAMTrialsExcluded(ismember(cellfun(@str2num,T.ParticipantNr),subjNames1)),'UniformOutput',false);
ft{2} = cellfun(@str2num,T.Bl2FAMTrialsExcluded(ismember(cellfun(@str2num,T.ParticipantNr),subjNames2)),'UniformOutput',false);

if false
    T.Bl1PotentialTrialsExcluded = cellfun(@(x)strrep(x,'0',''),T.Bl1PotentialTrialsExcluded,'UniformOutput',false);
    T.Bl2PotentialTrialsExcluded = cellfun(@(x)strrep(x,'0',''),T.Bl2PotentialTrialsExcluded,'UniformOutput',false);
    btp{1} = cellfun(@str2num,T.Bl1PotentialTrialsExcluded(ismember(cellfun(@str2num,T.ParticipantNr),subjNames1)),'UniformOutput',false);
    btp{2} = cellfun(@str2num,T.Bl2PotentialTrialsExcluded(ismember(cellfun(@str2num,T.ParticipantNr),subjNames2)),'UniformOutput',false);
    bt = cellfun(@(a,b)cellfun(@(x,y)union(x,y),a,b,'UniformOutput',false),bt,btp,'UniformOutput',false);
end

block_structure = logical([0 0 1 1 0 1 1 1; 0 1 1 0 1 1 1 0]);
for b = 1:2
    for k = 1:length(bt{b})
        thistest = ones(1,5);
        thisfam = ones(1,3);
        if length(bt{b}{k}) > 1
            thistest(bt{b}{k}) = 0;
            blockData{b}(k, block_structure(b,:)) = thistest;
        end
        if ~isempty(ft{b}{k}) && (length(ft{b}{k}) > 1 || (ft{b}{k}) > 0)
            thisfam(ft{b}{k}) = 0;
            blockData{b}(k, ~block_structure(b,:)) = thisfam;
        end
    end
end
% block1 = table2array(T(ismember(T.ParticipantNr,subjNames1),7:14)) == 1;
% block2 = table2array(T(ismember(T.ParticipantNr,subjNames2),15:22)) == 1;

countByBlock = [0 0];


%create subfolder to save the new .nirs files in
subfolder = sprintf('%s/clean',nirs_folder);
mkdir(subfolder);
for f = 1:size(nts_files,1)
    nirs_filename = strcat(nirs_folder, "/", nts_files(f));
    nirsdata = load(nirs_filename,'-mat');
    fprintf('opening %s\n',nirs_filename);
    block = cellfun(@(x)str2num(x{1}),regexp(nirs_filename,'.*_block(\d).nirs','tokens'));
    countByBlock(block) = countByBlock(block) + 1;
    
    trialstate = blockData{block}(countByBlock(block),:)'; % get inclusion state of trials by order of happening
    if any(~trialstate)
        disp('1')
    end
    varall = string(nirsdata.CondNames);
%     indx    = find(cellfun(@(x)~isempty(x),regexp(varall,['[' sprintf('%s',varnames(:)) ']'])));
    vardata = nirsdata.s;
    
    starts = find(vardata(:,strcmp(varall,'s')));   % get starting points for each trial
    if block == 1
        trialstate = trialstate(1:size(starts,1));      % remove non-occuring trials
    elseif block == 2
        if size(trialstate,1) == size(starts,1) + 1
            trialstate(end - 1) = [];
        elseif size(trialstate,1) > size(starts,1) + 1
            trialstate = trialstate(1:size(starts,1));
        end
    end
    ends = [starts(2:end); size(vardata,1)];
    allSegments = [starts ends];
    badSegments = allSegments(~trialstate,:);
    badSegmentsInd = zeros(size(vardata,1),1);
    badSegmentsInd(badSegments(:,1)) = 1;
    badSegmentsInd(badSegments(:,2)) = badSegmentsInd(badSegments(:,2)) -1;
    badSegmentsInd = logical(cumsum(badSegmentsInd));
    badSegmentsInd(end) = badSegmentsInd(end - 1);
    nirsdata.s(badSegmentsInd,:) = 0;
    
    % clean up wrong event name
    if any(contains(nirsdata.CondNames,'T'))
        nirsdata.CondNames{contains(nirsdata.CondNames,'T')} = 'F';
    elseif any(contains(nirsdata.CondNames,'F'))
        nirsdata.CondNames{contains(nirsdata.CondNames,'F')} = 'T';
    else
        error('error');
    end
    
    save(strcat(subfolder, "/", strrep(nts_files(f),".nirs","_clean.nirs")),'-struct','nirsdata','-mat');
%     if any(strcmp(varall,'b'))
%         disp('this')
%         break
%     end
%     for var = indx
%         new_pos                 = find(vardata(:,var)) + timejump*fs + hrlag*fs;
%         vardata(:,var)          = zeros(size(vardata(:,var)));
%         vardata(new_pos,var)    = 1;
%     end
%     nirsdata.s = vardata(:,indx);
%     nirsdata.CondNames = nirsdata.CondNames(indx);
%     %copyfile(nirs_filename, [nirs_filename '.bak'])
%     save([subfolder '/' strrep(nts_files{f},'.nirs','_editted.nirs')],'-struct','nirsdata','-mat');
end
end







