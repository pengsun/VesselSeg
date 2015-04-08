function tr_ubuntu_slices2_over_tmp4_over_tmp3()
%% init dag: from file
beg_epoch = 701;
dir_mo = fullfile('./mo_zoo/slices2_over_tmp4_over_tmp3');
dir_mo_from = fullfile('./mo_zoo/tmp4_over_tmp3');
fn_mo = fullfile(dir_mo_from, sprintf('ep_%d.mat', beg_epoch-1) );
h = create_dag_from_file (fn_mo);
%% config
h.beg_epoch = beg_epoch;
h.num_epoch = 900;
batch_sz    = 256;
fn_data     = fullfile('/home/ubuntu/A/data/defectoSeg_matlab/slices2.mat');

%% CPU or GPU
% h.the_dag = to_cpu( h.the_dag );
h.the_dag = to_gpu( h.the_dag );
%% peek and do something (printing, plotting, saving, etc)
hpeek = peek();
% plot training loss
% addlistener(h, 'end_ep', @hpeek.plot_loss);
% save model
hpeek.dir_mo = dir_mo;
addlistener(h, 'end_ep', @hpeek.save_mo);
%% initialize the batch data generator
tr_bdg = load_tr_data(fn_data, batch_sz);
%% do the training
train(h, tr_bdg);

function ob = create_dag_from_file (fn_mo)
load(fn_mo, 'ob');
% ob loaded and returned

function tr_bdg = load_tr_data(fn_data, bs)
load(fn_data);
ind_tr = (setId == 1);

Xtr = X(:,:,:, ind_tr);
Ytr = Y(:, ind_tr);
tr_bdg = bdg_memXd4Yd2(Xtr,Ytr,bs);