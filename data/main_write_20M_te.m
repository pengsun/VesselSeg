%%
K = 994;
% fn_info = fullfile('/home/ubuntu/A/data/defactoSeg2', 'info.mat');
fn_info = fullfile('D:\data\defactoSeg2', 'info.mat');
dir_out = fullfile(...
  fileparts(mfilename('fullpath')), '20M');

tarSetId = 3;
%%
diary( [mfilename,'.txt'] );
diary on;

fn_out = fullfile(dir_out, 'te.mat' );
write_matMhaDir2( fn_info, K, fn_out, tarSetId);
fprintf('done writing %s\n\n', fn_out);

diary off;