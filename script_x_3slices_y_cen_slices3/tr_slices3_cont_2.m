function tr_slices3_cont_2()
%% init dag: from file
beg_epoch   = 901;
dir_root    = fileparts(fileparts( mfilename('fullpath') ));
dir_mo      = fullfile(dir_root,'mo_zoo','slices3');
dir_mo_from = fullfile(dir_root,'mo_zoo','slices2_over_tmp4_over_tmp3');
fn_mo       = fullfile(dir_mo_from, sprintf('ep_%d.mat', beg_epoch-1) );

h = create_dag_from_file (fn_mo);
%% config
h.beg_epoch = beg_epoch;
h.num_epoch = 1050;
batch_sz    = 256;
dir_data    = fullfile(dir_root, 'data', 'slices3');

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
tr_bdg = load_tr_data(dir_data, batch_sz);
%% do the training
diary( [mfilename, '.txt'] );
diary on;

train(h, tr_bdg);

diary off;
function ob = create_dag_from_file (fn_mo)
load(fn_mo, 'ob');
% ob loaded and returned

function tr_bdg = load_tr_data(dir_data, bs)
matIds = 1 : 10;
tr_bdg = bdg_matInDir(dir_data, matIds, bs);
