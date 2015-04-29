%% 20M small mat
% The same with 20M, but small mat for asynchronous IO 
% For training only!
%%
Nmat = 200;
K = 500;
fn_info = fullfile('/home/ubuntu/A/data/defactoSeg2', 'info.mat');
% fn_info = fullfile('D:\data\defactoSeg2', 'info_med.mat');
%%
dir_out = fullfile(...
  fileparts(mfilename('fullpath')), '20M_sm');

diary( [mfilename,'.txt'] );
diary on;
for i = 1 : Nmat
  fn_out = fullfile(dir_out, [num2str(i),'.mat'] );
  
  write_matMhaDir2( fn_info, K,  fn_out);
  
  fprintf('done writing %s\n\n', fn_out);
end
diary off;