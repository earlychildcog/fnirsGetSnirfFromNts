function [dataSnirf] = snirfFromNirs(filePathNirs,filePathSnirf)
% requires homer3 and having run "setpaths.m"


if ~exist("filePathSnirf","var") || isempty(filePathSnirf)
    filePathSnirf = strrep(filePathNirs,".nirs",".snirf");
end

dataNirs = load(filePathNirs,"-mat");

dataSnirf = SnirfClass(dataNirs);
dataSnirf.Save(filePathSnirf);

