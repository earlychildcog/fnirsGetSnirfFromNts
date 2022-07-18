function removedata(datafolder, manualArtDetTable)

mdrt = readtable();


if ~exist('datafolder','var')
    datafolder = uigetdir('Select datafolder...');
end
files = arrayfun(@(x)x.name,[dir([datafolder '/*.nirs'])],'UniformOutput',false);
filesN = length(files);
for f = 1:filesN
    thisfile = files{f};
    nirsdata = load([datafolder '/' thisfile],'-mat');
    
    subjID = str2num(thisfile(1:3));
    block = cellfun(@str2num,regexp(thisfile,'\.*_block(\d)\.*','tokens','once'));
    thisrow = mdrt.subjID == subjID & mdrt.block == block;
    
    if any(thisrow)
        time2start = mdrt.start_time(thisrow);
        time2end = mdrt.end_time(thisrow);
        inclInd = nirsdata.t > time2start & nirsdata.t < time2end;
        nirsdata.t = nirsdata.t(inclInd);
        nirsdata.t = nirsdata.t - nirsdata.t(1);
        nirsdata.d = nirsdata.d(inclInd,:);
        nirsdata.s = nirsdata.s(inclInd,:);
        nirsdata.aux = nirsdata.aux(inclInd,:);
        fprintf('file %s',thisfile)
        copyfile([datafolder '/' thisfile],[datafolder '/' thisfile '.bak']);        % backup file
        save([datafolder '/' thisfile], '-mat','-struct','nirsdata');
        fprintf(' done\n');
    end
end







