%%
Nmat = 10;
K = 1000;
fn_info = fullfile('/home/ubuntu/A/data/defactoSeg', 'info.mat');
%%
dir_out = fileparts( mfilename('fullpath') );

diary( [mfilename,'.mat'] );
diary on;
for i = 1 : Nmat
  fn_out = fullfile(dir_out, [num2str(i),'.txt'] );
  
  write_matMhaDir( fn_info, K,  fn_out);
  
  fprintf('done writing %s\n\n', fn_out);
end
diary off;