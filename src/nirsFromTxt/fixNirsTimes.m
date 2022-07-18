function err = fixNirsTimes(nameFolderNirs)
err = 1;
nameFileAll = arrayfun(@(x)string(x.name), dir(nameFolderNirs + "/*.nirs"));
nFiles = length(nameFileAll);

for f = 1:nFiles
    nameFile = nameFileAll(f);
    x = load(nameFolderNirs + "/" + nameFile, "-mat");

    maxTime = size(x.d,1)/10-0.1;
    x.t = [0:0.1:maxTime]';

    save(nameFolderNirs + "/" + nameFile,"-struct","x","-mat")

end

err = 0;