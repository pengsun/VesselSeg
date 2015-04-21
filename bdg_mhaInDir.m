classdef bdg_mhaInDir < bdg_i
  %BDG_MHAINDIR Generate mha files in directory. A bdg_mhaxxx wrapper 
  %   Detailed explanation goes here
  
  properties
    mha_info;    % see create_mha_info()
    mha_info_wk; % working mha_info
    
    nm_per_ep;  % #mha per epoch
    nb_per_mha; % #batches per mha 
    cur_i_mha;  % current mha
    
    bs;      % batch size
    h_get_x; % handle to getting x
    h_get_y; % handle to getting y
    
    class_bdg; % handle to bdg (class name)
    h_bdg;     % working bdg_mha2
  end
  
  properties
    xMean;
    vmin;
    vmax;
  end
  
  methods % implement the bdg_i interfaces
    function ob = bdg_mhaInDir(the_dir, names, bs, h_getx, h_gety, class_bdg)
      % initialize the file name list
      ob.mha_info = create_mha_info();
      ob = set_fns (ob, the_dir, names);
      % record
      ob.bs      = bs;
      ob.h_get_x = h_getx;
      ob.h_get_y = h_gety;
      % default params
      ob.cur_i_mha  = 1;
      ob.nm_per_ep  = 4;
      ob.nb_per_mha = 16;
      % set internal bdg
      ob.class_bdg = class_bdg;
      
    end % bdg_mhaInDir
    
    function ob = reset_epoch(ob)
      ob = set_working_mha_info(ob);
      ob = switch_to_batInMha(ob, 1);
      ob.h_bdg = reset_epoch(ob.h_bdg);
    end
    
    function data = get_bd(ob, i_bat)
      [ob, i_batInMha] = switch_to_batInMha(ob, i_bat);
      data = get_bd( ob.h_bdg, i_batInMha );
    end % get_bd
    
    function data = get_bd_orig (ob, i_bat)
      error('not implemented yet.');
    end % get_bd_orig
    
    function N = get_bdsz (ob, i_bat)
      [ob, i_bat_in_mha] = switch_to_batInMha(ob, i_bat);
      N = get_bdsz(ob.h_bdg, i_bat_in_mha);
    end % get_bdsz
    
    function nb = get_numbat (ob)
      nb = ob.nb_per_mha * ob.nm_per_ep ;
    end % get_numbat
    
    function ni = get_numinst (ob)
      ni = ob.bs * get_numbat(ob);
    end % get_numinst
    
  end % methods
  
  methods % auxiliary
    function [ob, i_batInMha] = switch_to_batInMha(ob, i_bat)
      i_mha = ceil( i_bat ./ ob.nb_per_mha);
      i_batInMha = mod(i_bat, ob.nb_per_mha);
      
      if (i_mha ~= ob.cur_i_mha)
        ob = set_working_bdg(ob, i_mha);
        ob.cur_i_mha = i_mha;
        return;
      end
      
      if ( isempty(ob.h_bdg) )
        ob = set_working_bdg(ob, i_mha);
      end
    end % switch_to_batInMha
    
    function ob = set_working_bdg(ob, i_mha)
      clear ob.h_bdg;
      
      % create new
      fprintf('loading new mha file %s...', ...
              fileparts(ob.mha_info(i_mha).fn_mha) );
      t = tic;
      mha   = mha_read_volume( ob.mha_info_wk(i_mha).fn_mha );
      mk_fg = mha_read_volume( ob.mha_info_wk(i_mha).fn_mk_fg );
      mk_bg = mha_read_volume( ob.mha_info_wk(i_mha).fn_mk_bg );
      ob.h_bdg = ob.class_bdg(mha, mk_fg, mk_bg, ...
                              ob.bs, ...
                              ob.h_get_x, ob.h_get_y);
      t = toc(t);                      
      fprintf('done. Time spent = %d seconds\n', t);
      
      % do nothing further if unset
      if ( isempty(ob.xMean) || isempty(ob.vmin) || isempty(ob.vmax) )
        return;
      end
      ob.h_bdg.xMean = ob.xMean;
      ob.h_bdg.vmin  = ob.vmin;
      ob.h_bdg.vmax  = ob.vmax;
      
    end % set_working_bdg
    
    function ob = set_fns (ob, the_dir, names)
    % for each mha_info(i), set
    %   .fn_mha, .fn_mk_fg and .fn_mk_bg
      for i = 1 : numel(names)
        nm = names{i};
        ob.mha_info(i).fn_mha   = fullfile(the_dir, nm, 'tu.mha');
        ob.mha_info(i).fn_mk_fg = fullfile(the_dir, nm, 'maskv3.mha');
        ob.mha_info(i).fn_mk_bg = fullfile(the_dir, nm, 'maskbb.mha');
      end % for
    end % set_fns
    
    function ob = set_working_mha_info(ob)
      N = numel(ob.mha_info);
      ob.mha_info_wk = ob.mha_info( randsample(N, ob.nm_per_ep) );
    end
  end % methods 
  
end % bdg_mhaInDir

function st = create_mha_info ()
  st = struct(...
    'fn_mha',   '',... % full file name for mha
    'fn_mk_fg', '',...
    'fn_mk_bg', '',...
    'i_bat',    1);    % current batch count
end

