% streamline script to run following experiments for wacv2020 style paper Pb
% eval
% Experiment steps
% 1. generate pb map given the weight, content, style sample
% 2. (optional) re-organize stylized images and Pb maps file structure
% 3. use evaluztion scripts to evaluate on Pb and generate eval file for
% every image
% 4. collect boundary evaluation results from all eval files
% 5. may repeat step 1-4 for multiple set of sample parameter combinations

%% configurations params

addpath ../bench/benchmarks
addpath ../bench
addpath ../grouping/lib


clear all;close all;clc;


% do not modify these parameters
PERM_GT = false;
isBoosting = false;
boosting_iter = 1;

%%%%%%%%%%%%%%%%%%%methods spec%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%% sample files%%%%%%%%%%%%%%%%%%%%%%
% files that lists "weight, contentId, styleId" at each row
% for universal style transfer, model weights from 0 to 1 is linearly mapped
% to 0 to 2000 to accommendate evaluations on Gatys and Crosslayer. 
sample_file = './wcs3.txt'; 
this_trial = 'round1';

% %first batch 300 samples from gatys
% method = 'Gatys';
% imgFolder = 'Gatysampled15';

% %first batch 300 samples from crosslayer
% method = 'CrossLayer';
% imgFolder = 'AddCrossampled15';

%first batch 300 samples from universal style transfer
method = 'Universal';
imgFolder = 'AddCrossampled15';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
img_dir = '../BSDS500/data/images';
gtDir = '../BSDS500/data/groundTruth';
rstDir = '../BSDS500/ucm2/SampleTests';

SampleImgDir = fullfile(img_dir,imgFolder);
rstDir = fullfile(rstDir,method);

PbOutDir = fullfile(rstDir,'PbRsts');

if PERM_GT == 0
    gtDir = fullfile(gtDir,'test');
else
    gtDir = fullfile(gtDir,'test_selected_perm');
end
   
if PERM_GT ==0
    EvalOutDir = fullfile(rstDir,strcat(this_trial,'_eval'));
    Eval_stat_outDir = fullfile(rstDir,strcat(this_trial,'_eval_sum'));
else
    EvalOutDir = fullfile(rstDir,strcat(this_trial,'_perm_eval'));
    Eval_stat_outDir = fullfile(rstDir,strcat(this_trial,'_perm_eval_sum'));
end

mkdir(EvalOutDir);
mkdir(Eval_stat_outDir);

%% open parallel pool if you have parallel computing license
% open parpool
% delete(gcp);
% parpool('local_Copy',8); %6/8 workers

%% get Pb maps

% note all stylized images should be stored in one folder, so as the Pb maps
% it is untill when evaluated, samples from different trial will be stored
% in indivisual folders.

%read from wcs file
samples = dlmread(sample_file);
image_names = getImgnamesBySample(samples); % return an cell array of image filenames, copy images to directory
mkdir(PbOutDir);
all_file_dir(1:length(image_names)) = struct('name',[],'folder',[],'date',[],'bytes',[],'isdir',[],'datenum',[]);

% change for to parfor if parallel package is available
for i =1:numel(image_names)
    
    PbOutFile = fullfile(PbOutDir,[image_names{i}(1:end-4) '.mat']); 
    imgFile=fullfile(SampleImgDir,image_names{i});
    
    if ~exist(imgFile,'file')
        imgFile = strrep(imgFile,'.png','.jpg');
    end
    
    disp(imgFile)
    all_file_dir(i) = dir(imgFile);
    if exist(PbOutFile,'file'), continue; end
    %[ucm2] = im2ucm(imgFile, PbOutFile);
    gPb_orient = globalPb(imgFile, PbOutFile);
    ucm2 = contours2ucm(gPb_orient, 'doubleSize');

    save(PbOutFile,'ucm2');
    disp(ucm2);
    figure; imshow(ucm2);
end

%% evaluation 

tic;
%inFile = fullfile(pbDir, strcat(imgFile.name(1:end-4),'.mat'));
filename_splits = strsplit(dir(imgFile).name,'_');
gt_file_name = strrep(filename_splits{2},'content','');    
gtFile = fullfile(gtDir, strcat(gt_file_name,'.mat'));

evFile = fullfile(EvalOutDir, strcat(dir(imgFile).name(1:end-4),'_ev1.txt'));
S = dir(fullfile(EvalOutDir, strcat(dir(imgFile).name(1:end-4),'_*')));
num = length(S)+1;
evFile_new = fullfile(EvalOutDir, strcat(dir(imgFile).name(1:end-4),'_',num2str(num),'_ev1.txt'));
%copyfile(evFile,evFile_new)
evaluation_bdry_image(PbOutFile, gtFile, evFile_new)
toc;



%% collect eval rsts and generate AUC
% note this needs to be executed for every weights

iter =1;
if isBoosting, iter = boosting_iter;end 
sum_AUC = zeros(iter,1); 
   
for k=1:iter
   fprintf('iter: %d\n',k)
    % randomly sample image to evaluate, sort of like boosting
    if isBoosting,
        iids = cell(length(image_names),1);

        for j = 1:numel(all_file_dir),      
            iids{j} = all_file_dir(randi(length(all_file_dir))).name;
        end
    else
        iids = all_file_dir;
    end
    
    %  get per image AUCs
    eval_file_dirs = fullfile(EvalOutDir,strrep(strrep({iids.name},'.png','_ev1.txt'),'.jpg','_ev1.txt'));
    AUCs = zeros(length(eval_file_dirs),1);
    
    this_weight_eval_stat_ourDir = fullfile(Eval_stat_outDir,'all');
    mkdir(this_weight_eval_stat_ourDir);
        
    for j = 1:length(eval_file_dirs)

       [bestF, bestP, bestR, bestT, F_max, P_max, R_max, Area_PR] = collect_eval_bdry_sty(this_weight_eval_stat_ourDir,eval_file_dirs(j));
        AUCs(j) = Area_PR;
        
    end
      rsts = [samples AUCs];
     save(fullfile(this_weight_eval_stat_ourDir,[method '_everyImgAUC.mat']),'rsts');
    
end 


