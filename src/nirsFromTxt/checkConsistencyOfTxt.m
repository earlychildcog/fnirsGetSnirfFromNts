function checkConsistencyOfTxt(datafolder)


if ~exist('datafolder','var')
    datafolder = uigetdir('Select datafolder...');
end
% outsubfolder = 'blocks';
% mkdir([datafolder '/' outsubfolder]);
files = arrayfun(@(x)string(x.name), dir(strcat(datafolder, "/*txt")));
linesPerTimepoint = 16;
fprintf('Opening folder %s\n', datafolder);
fileN = size(files,1);
parfor f=1:fileN
    thisFile = files(f);
    fn = strcat(datafolder,"/",thisFile);
    fprintf('Constistency check on %s...',thisFile);
    T = readtable(fn);
    Tdiff = diff(T.Var1);
    changes = find(Tdiff ~= 0);
    assert(all(mod(changes,linesPerTimepoint) == 0), 'Consistency check failed in %s',thisFile);
    changes2 = changes/linesPerTimepoint;
    if any(changes2 ~= [1:size(changes2,1)]')
        fprintf(' ok, though missing %d timepoint(s)?\n',sum(diff(changes2)-1));
    else
        fprintf(' ok\n');
    end
%     warning(all(changes2 == [1:size(changes2,1)]'), 'Consistency check failed, missing timepoint in %s',files{f});
    
end