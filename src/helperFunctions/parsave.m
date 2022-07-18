function parsave(fname, s)
% saves the variables stored in structure $s to the file $fname
save(fname,'-struct','s','-mat')