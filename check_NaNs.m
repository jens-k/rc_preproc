filepath = 'D:\Sleep\DataDownload\Preprocessing_250Hz\';

files = dir(strcat(filepath,'*.mat'));

for file = 1:numel(files)
    
    count = 0;
    load(strcat(filepath,files(file).name))
    
    data = data_downsamp_250.trial;
    
    for trial = 1:numel(data)
        
        tempdata = data{1,trial};
        
        if(isnan(tempdata))
            count = count+1;
        end
    end
    
    if count>0
        files(file).name
    end
    
end