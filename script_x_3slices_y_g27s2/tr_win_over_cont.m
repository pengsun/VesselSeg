function tr_win_over_cont()
  %% config
  beg_epoch   = 901;
  dir_mo_root = fileparts(fileparts(mfilename('fullpath')));
  dir_mo      = fullfile(dir_mo_root, ...
                         'mo_zoo', 'g27_s2');
  dir_mo_from = fullfile(dir_mo_root, ...
                         'mo_zoo', 'slices2_over_tmp4_over_tmp3');
  
  num_epoch  = 903;
  batch_sz   = 256;
  nb_per_mha = 50;
  
  dir_data    = 'D:\data\defactoSeg';
  fn_dataInfo = fullfile(dir_data, 'info_small.mat');
  %% init dag: from file
  fn_mo = fullfile(dir_mo_from, sprintf('ep_%d.mat', beg_epoch-1) );
  h = create_dag_from_file (fn_mo);
  h.beg_epoch  = beg_epoch;
  h.num_epoch  = num_epoch;
  
  function ob = create_dag_from_file (fn_mo)
    load(fn_mo, 'ob'); % ob loaded 
    
    %%% hack: change the output dimensions: 2 -> 27
    f    = 0.1;
    nout = 27;
    % the weight
    ww = ob.the_dag.tfs{1,10}.p(1,1);
    sz = size(ww.a);
    % the bias
    bb = ob.the_dag.tfs{1,10}.p(1,2);
    % re-initialize
    ww.a = f .* randn( [sz(1:3), nout], 'like', ww.a);
    bb.a = zeros([1,nout], 'like', bb.a);
    
    %%% hack: reset the corresponding opt_arr
    ob.opt_arr(end-1).delta = zeros(size(ww.a), 'like', ww.a);
    ob.opt_arr(end).delta   = zeros(size(bb.a), 'like', bb.a);
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
  tr_bdg = load_tr_data();
  tr_bdg.nb_per_mha = nb_per_mha;
  
  function tr_bdg = load_tr_data()
    st = load(fn_dataInfo);
    
    % get the training data
    names = st.imgNames( st.imgSetId == 1 );
    
    % the batch data generator: a directory walker
    tr_bdg = bdg_mhaInDir(...
      dir_data, names, ...
      batch_sz, @get_x_3slices, @get_y_g27s2, @bdg_mha2);
    
    % get the statistics on training data
    tr_bdg.xMean = st.Xm;
    tr_bdg.vmin  = st.vmin;
    tr_bdg.vmax  = st.vmax;
  end
  %% do the training
  train(h, tr_bdg);
end