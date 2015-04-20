function tr_win_over_tmp4_over_tmp3()
  %% config
  beg_epoch   = 501;
  dir_mo      = fullfile('mo_zoo/tmp4_over_tmp3');
  dir_mo_from = fullfile('mo_zoo/tmp3');
  
  num_epoch   = 700;
  batch_sz    = 256;  
  
  dir_data = 'D:\data\defactoSeg_matlab';
  fn_dataInfo = 'D:\data\defactoSeg_matlab\info.mat';
  %% init dag: from file
  fn_mo = fullfile(dir_mo_from, sprintf('ep_%d.mat', beg_epoch-1) );
  h = create_dag_from_file (fn_mo);
  h.beg_epoch = beg_epoch;
  h.num_epoch = num_epoch;
  
  function ob = create_dag_from_file (fn_mo)
    load(fn_mo, 'ob'); % ob loaded 
    
    % hack: change the output dimensions
    f    = 0.1;
    nout = 27;
    % the weight
    ww = ob.the_dag.tfs{1,10}.p(1,1);
    sz = size(ww.a);
    % the bias
    bb = ob.the_dag.tfs{1,10}.p(1,2);
    % re-initialize
    ww.a = f .* randn( [sz(1:3), nout], 'single');
    bb.a = zeros([1,nout], 'single');
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
  
  function tr_bdg = load_tr_data()
    % TODO: set names
    load(fn_dataInfo);
    names = [];
    
    tr_bdg = bdg_mhaInDir(...
      dir_data, names, ...
      batch_sz, @get_x_3slices, @get_y_g27s2, @bdg_mha2);
    % TODO
    tr_bdg.xMean = [];
    tr_bdg.vmin  = [];
    tr_bdg.vmax  = [];
  end
  %% do the training
  train(h, tr_bdg);
end