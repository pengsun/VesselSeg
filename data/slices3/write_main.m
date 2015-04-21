%%
Nmat = 3;
K = 100;
fn_info = fullfile('D:\data\defactoSeg', 'info_small.mat');
%%
dir_out = fileparts( mfilename('fullpath') );
for i = 1 : Nmat
  fn_out = fullfile(dir_out, [num2str(i),'.mat'] );
  
  write_matMhaDir( fn_info, K,  fn_out);
  
  fprintf('done writing %s\n\n', fn_out);
end