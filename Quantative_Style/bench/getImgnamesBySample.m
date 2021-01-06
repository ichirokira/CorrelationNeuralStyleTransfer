function [image_names] = getImgnamesBySample(samples)
% given img folder, sampleImg folder and sample indicies
% return an cell array of image filenames, copy images to directory

% get parameters from samples

num_samples = size(samples,1);
image_names = cell(num_samples,1);

% for i=1:num_samples
%    weight = num2str(samples(i,1));
%    content = num2str(samples(i,2));
%    style  = num2str(samples(i,3));
%    
%    filename = strcat('weight',weight,'_content',content,'_style',style,'.png');
%    image_names{i} = filename;
%     
% end
for i=1:num_samples
   style = num2str(samples(i,1));
   content = num2str(samples(i,2));
   method  = samples(i,3);
   iteration = num2str(samples(i,4));
   
   if method == 1
       filename = strcat('style',style,'_content',content,'_','gramMatrix','_iteration',iteration,'.png');
   elseif method == 2
       filename = strcat('style',style,'_content',content,'_','Pearson','_iteration',iteration,'.png');
   elseif method == 3
       filename = strcat('style',style,'_content',content,'_','Covariance','_iteration',iteration,'.png');
   elseif method == 4
       filename = strcat('style',style,'_content',content,'_','Euclidean','_iteration',iteration,'.png');
   elseif method == 5
       filename = strcat('style',style,'_content',content,'_','CosineSimilarity','_iteration',iteration,'.png');
   end
   
   image_names{i} = filename;
    
end


end