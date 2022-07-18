function splitRowFiles(datafolderIN, datafolderOUT, exclfile)

if ~exist('datafolderIN','var')
    datafolderIN = uigetdir('Select datafolder...');
end
outsubfolder = strcat(datafolderOUT,"/blocks");
mkdir(strcat(datafolderIN,"/",outsubfolder));
files = arrayfun(@(x)string(x.name),dir(strcat(datafolderIN,"/*txt")));

% blockCoding = readtable('block_coding.csv');

if ~exist('exclfile','var')
    exclfile = uigetfile('Select .nirs data folder...');
end
blockCoding = readtable(exclfile);
blockCoding.block1 = blockCoding.Bl1Included > 0;       % put == 1 for including only non-ambigious, >0 for all ambiguous
blockCoding.block2 = blockCoding.Block2Included > 0;
% blockCoding.block1 = blockCoding.block1 > 0;
% blockCoding.block2 = blockCoding.block2 > 0;
% blockCoding.block1 = blockCoding.block1 & (blockCoding.mask1 == 1);
% blockCoding.block2 = blockCoding.block2 & (blockCoding.mask2 == 1);

% how much we put after last movie in block 1 for outcome phase
% padding_block1 = 64;
% padding_block2 = 64;
padding_block1 = 2;
padding_block2 = 0;
linesPerTimepoint = 16;
fs = 10;
filesN = length(files);
fprintf("Starting splitting blocks...")

parfor f=1:filesN
    storeLines = {};
    fn = files(f);
    newfn1 = strrep(fn,".txt","_block1.txt");
    newfn2 = strrep(fn,".txt","_block2.txt");
    
    subjNum = str2num(extractBefore(fn,4));
    block1In = blockCoding.block1(blockCoding.ParticipantNr == subjNum);
    block2In = blockCoding.block2(blockCoding.ParticipantNr == subjNum);
    
    fin = fopen(strcat(datafolderIN,"/", fn),'r');
    if block1In
        fout = fopen(strcat(datafolderIN,"/",outsubfolder,"/",newfn1),'w');
    end
    tline = fgetl(fin);

    Tblock = 't';
    Iblock = 'i';
    ChangeBlock = 'c';
    block = 1;
    lineCount = 0;
    while ischar(tline)
        %disp(tline)
        if block == 1
            if contains(tline,ChangeBlock)
                % add 64s padding for hr for outcome phase for first block
                if block1In
                    fprintf( fout, '%s\n', tline);
                end
                
                block = block + 0.5;
                
            elseif block1In
                fprintf( fout, '%s\n', tline);
            end
        elseif block == 1.5
            if contains(tline,Tblock) || contains(tline,Iblock)
                block = block + 0.5;
                
                if block1In
                    fclose(fout);
                end
                if block2In
                    fout = fopen(strcat(datafolderIN, "/", outsubfolder, "/", newfn2),'w');
                else
                    break
                end
                if block2In
                    if lineCount < padding_block2*fs*linesPerTimepoint
                        disp(lineCount);
                        addlinesN = floor(lineCount/linesPerTimepoint)*linesPerTimepoint;
                    else
                        addlinesN = padding_block2*fs*linesPerTimepoint;
                    end
                    for addCountBack = addlinesN:-1:1
                        fprintf( fout, '%s\n', storeLines{lineCount-addCountBack+1});
                    end
                    fprintf( fout, '%s\n', tline);
                end
            else
                lineCount = lineCount + 1;
                storeLines{lineCount} = tline;
                if block1In && lineCount < padding_block1*fs*linesPerTimepoint
                    fprintf( fout, '%s\n', tline);
                end
            end
        elseif block == 2 && block2In
            fprintf( fout, '%s\n', tline);
        end
        tline = fgetl(fin);
    end
    fclose(fin);
    if block2In
        fclose(fout);
    end
end