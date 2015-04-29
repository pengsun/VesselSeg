function err =  te_oneImg(varargin)
%%% config 
batch_sz = 1024; 
dir_mo = 'D:\CodeWork\git\VesselSeg\mo_zoo';
fn_mo = fullfile(dir_mo, '\20M\ep_1000.mat');
% instances, labels...
name     = '01-001-MAP';
dir_name = fullfile('D:\data\defactoSeg2\', name);
fn_mha   = fullfile(dir_name, 't.mha');        % the CT volume
fn_fg    = fullfile(dir_name, 'maskv3.mha');   % the fore-ground
fn_bg    = fullfile(dir_name, 'maskb.mha');    % the back-ground
% output file name
fn_out    = fullfile('.\', [name,'_pre.mha']);
fn_out_fg = fullfile('.\', [name,'_pre_fg.mha']);
fn_out_bg = fullfile('.\', [name,'_pre_bg.mha']);
fn_out_s  = fullfile('.\', [name,'_pre_s.mha']);


%%% load
% load mean, vmin, vmax
load('C:\Temp\slices2.mat', 'Xm','vmin','vmax');
% load data 
fprintf('loading volume %s...', fn_mha);
te_bdg = load_te_data(fn_mha,fn_fg,fn_bg, batch_sz);
te_bdg.xMean = Xm;
te_bdg.vmin  = vmin;
te_bdg.vmax  = vmax;
fprintf('data\n');
% load model
fprintf('loading model %s...', fn_mo);
load(fn_mo);
fprintf('done\n');

%%% statistics
tmp = (te_bdg.mk_fgbg > 0);
fprintf('# mask pixels = %d\n', sum( tmp(:) ) );
tmp = (te_bdg.mk_fgbg == 255);
fprintf('# foreground mask pixels = %d\n', sum( tmp(:) ) );
tmp = (te_bdg.mk_fgbg == 128);
fprintf('# background mask pixels = %d\n', sum( tmp(:) ) );
  

%%% do the job: testing it
Ypre = test(ob, te_bdg);
Ypre = gather(Ypre);


%%% show the error
Ygt = get_all_Ygt(te_bdg);
[err, err_one, err_two] = get_cls_err(Ypre, Ygt);
fprintf('classification error = %0.3f\n', err );
fprintf('background misclassfication rate = %0.3f\n', err_one );
fprintf('foreground misclassfication rate = %0.3f\n', err_two );


%%% restore prediction to mask and wirte 
% out = get_pre_mask(Ypre, te_bdg);
% mhawrite(fn_out, out, [1,1,1]);
% 
% out_fg = out;
% out_fg(out==128) = 0;
% mhawrite(fn_out_fg, out_fg, [1,1,1]);
% 
% out_bg = out;
% out_bg(out==255) = 0;
% mhawrite(fn_out_bg, out_bg, [1,1,1]);

%%% restore prediction to vesselness scores and write
out_s = get_pre_score(Ypre, te_bdg);
mhawrite(fn_out_s, out_s);


function te_bdg = load_te_data(fn_mha,fn_fg,fn_bg, batch_sz)
mha   = mha_read_volume(fn_mha);
mk_fg = mha_read_volume(fn_fg);
mk_bg = mha_read_volume(fn_bg);

% ---- debug
% step = [4,4,4];
% mha   = subsample(mha, step);
% mk_fg = subsample(mk_fg, step);
% mk_bg = subsample(mk_bg, step);
% % write
% mha_write('.\mk_fg.mha', mk_fg, [1,1,1], 'uint8');
% mha_write('.\mk_bg.mha', mk_bg, [1,1,1], 'uint8');
% ---- debug

te_bdg = bdg_mha(mha, mk_fg, mk_bg, batch_sz);


function out = get_pre_mask(Ypre, te_bdg)
out = zeros(size(te_bdg.mk_fgbg), 'uint8');

i_fg = te_bdg.ix_fgbg( Ypre(2,:) > Ypre(1,:) );
i_bg = te_bdg.ix_fgbg( Ypre(1,:) >= Ypre(2,:) );
assert( (numel(i_fg) + numel(i_bg)) == numel(te_bdg.ix_fgbg) );

out(i_fg) = 255;
out(i_bg) = 128;

function out = get_pre_score(Ypre, te_bdg)
out = zeros(size(te_bdg.mk_fgbg), 'single');

s = Ypre(2,:) - Ypre(1,:);
out( te_bdg.ix_fgbg ) = single( s(:) );


function xsub = subsample(x, step)
xsub = x(1:step(1):end, 1:step(2):end, 1:step(3):end );