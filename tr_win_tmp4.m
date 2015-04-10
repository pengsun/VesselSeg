function tr_win_tmp4()
%% init dag: from file
% beg_epoch = 201;
% dir_mo = fullfile('mo_zoo/tmp4');
% fn_mo = fullfile(dir_mo, sprintf('ep_%d.mat', beg_epoch-1) );
% h = create_dag_from_file (fn_mo);
% flag_from_scratch = false;
%% init dag: from scratch
beg_epoch = 1; 
dir_mo = fullfile('mo_zoo/tmp4');
h = create_dag_from_scratch ();
flag_from_scratch = true;
%% config
h.beg_epoch = beg_epoch;
h.num_epoch = 500;
batch_sz    = 256;
fn_data     = fullfile('C:\Temp\tmp4.mat');
%% (re-)initialize parameters
if (flag_from_scratch)
  h = init_params(h);
end
%% choose the numeric optimization algorithms
if (flag_from_scratch)
  h = init_opt(h);
end
%% CPU or GPU
% h.the_dag = to_cpu( h.the_dag );
h.the_dag = to_gpu( h.the_dag );
%% peek and do something (printing, plotting, saving, etc)
hpeek = peek();
% plot training loss
addlistener(h, 'end_ep', @hpeek.plot_loss);
% save model
hpeek.dir_mo = dir_mo;
addlistener(h, 'end_ep', @hpeek.save_mo);
%% initialize the batch data generator
tr_bdg = load_tr_data(fn_data, batch_sz);
%% do the training
train(h, tr_bdg);


function h = create_dag_from_scratch ()
h = dag_mb();
h.the_dag = tfw_seg();
  

function ob = create_dag_from_file (fn_mo)
load(fn_mo, 'ob');
% ob loaded and returned


function h = init_params(h)
NH = 16; % # hidden units
f = 0.1;
% parameter layer I, conv
h.the_dag.p(1).a = f*randn(3,3,3,NH, 'single') ; % kernel
h.the_dag.p(2).a = zeros(1, NH, 'single');       % bias
% parameter layer II, conv
h.the_dag.p(3).a = f*randn(2,2,NH,NH, 'single'); 
h.the_dag.p(4).a = zeros(1,NH,'single');        
% parameter layer III, conv
h.the_dag.p(5).a = f*randn(2,2,NH,NH, 'single'); 
h.the_dag.p(6).a = zeros(1,NH,'single');        
% parameter layer IV, conv 1x1
h.the_dag.p(7).a = f*randn(1,1,NH,NH, 'single'); 
h.the_dag.p(8).a = zeros(1,NH,'single');     
% parameter layer V, output
h.the_dag.p(9).a  = f*randn(5,5,NH,2, 'single'); 
h.the_dag.p(10).a = zeros(1,2,'single');   


function h = init_opt(h)
num_params = numel(h.the_dag.p);
h.opt_arr = opt_1storder();
h.opt_arr(num_params) = opt_1storder();

% rr = [0.01, 0.005, 0.001, 0.001];
rr = 0.001 * ones(1, 5);
for i = 1 : numel(rr)
  h.opt_arr( 2*(i-1) + 1 ).eta = rr(i);
  h.opt_arr( 2*(i-1) + 2 ).eta = rr(i);
end


function tr_bdg = load_tr_data(fn_data, bs)
load(fn_data);
ind_tr = (setId == 1);

Xtr = X(:,:,:, ind_tr);
Ytr = Y(:, ind_tr);
tr_bdg = bdg_memXd4Yd2(Xtr,Ytr,bs);