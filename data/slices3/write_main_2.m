%%
Nmat = 10;
K = 1000;
fn_info = fullfile('D:\data\defactoSeg', 'info.mat');
%%
dir_out = fileparts( mfilename('fullpath') );
for i = 1 : Nmat
  fn_out = fullfile(dir_out, [num2str(i),'.mat'] );
  
  write_matMhaDir( fn_info, K,  fn_out);
  
  fprintf('done writing %s\n\n', fn_out);
end