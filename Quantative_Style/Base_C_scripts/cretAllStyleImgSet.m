clc; clear

% create calibration experiment one. style transfer split original content

method = 'allStyle';
imgFolder = 'AllStyleSampled';

originalImgFolder = 'test';
img_dir = '../BSDS500/data/images';
style_dir = './50styles';

sample_file = './wcs1.txt';
samples = dlmread(sample_file);
image_names = getImgnamesBySample(samples); % return an cell array of image filenames, copy images to directory

original_img_dir = fullfile(img_dir,originalImgFolder);
target_img_dir = fullfile(img_dir,imgFolder);
mkdir(target_img_dir);

for i = 1:length(image_names)
   tarImgFilename =  fullfile(target_img_dir,image_names{i});
   originalContentFilename = fullfile(original_img_dir,strcat(num2str(samples(i,2)),'.jpg'));
   contentIm = imread(originalContentFilename);
   originalStyleFilename = fullfile(style_dir,['styles - ' num2str(samples(i,3)) '.jpg']);
   styleIm = imread(originalStyleFilename);
   
   content_size = size(contentIm);
   reshaped_styleIm = imresize(styleIm,content_size(1:2));
   
   imwrite(reshaped_styleIm,tarImgFilename)
end