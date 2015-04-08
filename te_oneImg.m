function [err_ep, err] =  te_oneImg(varargin)

% config 
ffn_mo = fullfile('.\epep.mat');
batch_sz = 8; 
fn_mat = fullfile('.\tmp3.mat');
img_id = 78;

% load data 
fprintf('loading data %s...', fn_mat);
te_bdg = load_te_data(fn_mat, img_id, batch_sz);
fprintf('data\n');

% load model
fprintf('loading model %s...', ffn_mo);
load(ffn_mo);
fprintf('done');
  
% do the job: testing it
Ypre = test(ob, te_bdg);
Ypre = gather(Ypre);

% show the error
err = get_cls_err(Ypre, te_bdg.Y);
fprintf('classification error = %0.3f\n', err );



function te_bdg = load_te_data(fn_data, iid, bs)
load(fn_data, 'X','Y','imgId');
ind_te = find( imgId == iid );
assert( numel(ind_te)>2 );

xx = X(:,:,:, ind_te);
yy = Y(:, ind_te);

te_bdg = bdg_memXd4Yd2(xx,yy, bs);

function err = get_cls_err(Ypre, Y)
[~, label_pre] = max(Ypre,[], 1);
[~, label]     = max(Y,[],    1);
N = numel(label);
err = sum( label_pre ~= label ) / N;
