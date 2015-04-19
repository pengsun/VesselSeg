classdef bdg_mhaInDir
  %BDG_MHAINDIR Generate mha files in directory. A bdg_mhaxxx wrapper 
  %   Detailed explanation goes here
  
  properties
    tr_info;    % see create_tr_info()
    nb_per_mha; % #batches per mha 
    cur_i_mha;  % current mha
    
    bs;
    h_get_x;
    h_get_y;
    
    class_bdg; % class name of
    h_bdg; % working bdg_mha2
  end
  
  methods % implement the bdg_i interfaces
    function ob = bdg_mhaInDir(the_dir, names, bs, h_getx, h_gety, class_bdg)
      % initialize the file name list
      ob.tr_info = create_tr_info();
      ob =  set_fns (the_dir, names);
      % record
      ob.bs     = bs;
      ob.h_get_x = h_getx;
      ob.h_get_y = h_gety;
      % init
      ob.cur_i_mha  = 1;
      ob.nb_per_mha = 16;
      % set internal bdg
      ob.class_bdg = class_bdg;
      ob = set_working_bdg(ob, ob.cur_i_mha);
      
    end % bdg_mhaInDir
    
    function data = get_bd(ob, i_bat)
      [ob, i_bat_in_mha] = switch_to_batInMha(ob, i_bat);
      data = get_bd( ob.h_bdg, i_bat_in_mha );
    end % get_bd
    
    function data = get_bd_orig (ob, i_bat)
      error('not implemented yet.');
    end % get_bd_orig
    
    function N = get_bdsz (ob, i_bat)
      [ob, i_bat_in_mha] = switch_to_batInMha(ob, i_bat);
      N = get_bdsz(ob, i_bat_in_mha);
    end % get_bdsz
    
    function nb = get_numbat (ob)
      nb = ob.nb_per_mha * numel( ob.tr_info ) ;
    end % get_numbat
    
    function ni = get_numinst (ob)
      ni = ob.bs * get_numbat(ob);
    end % get_numinst
    
  end % methods
  
  methods % auxiliary
    function [ob, i_bat_in_mha] = switch_to_batInMha(ob, i_bat)
      i_mha = ceil( i_bat ./ ob.nb_per_mha);
      i_bat_in_mha = mod(i_bat, ob.nb_per_mha);
      
      if (i_mha ~= ob.cur_i_mha)
        ob = set_working_bdg(ob, i_mha);
      end
    end % switch_to_batInMha
    
    function ob = set_working_bdg(ob, i_mha)
      clear(ob.h_bdg);
      
      % create new
      name = fileparts( fileparts( ob.tr_info(i_mha).fn_mha ) );
      fprintf('loading new mha files %s...', name);
      mha   = mha_read_volume( ob.tr_info(i_mha).fn_mha );
      mk_fg = mha_read_volume( ob.tr_info(i_mha).fn_mk_fg );
      mk_bg = mha_read_volume( ob.tr_info(i_mha).fn_mk_bg );
      ob.h_bdg = ob.class_bdg(mha, mk_fg, mk_bg, ob.bs, ob.y_mode);
      fprintf('done\n');
      
      % do nothing further if unset
      if ( isempty(ob.xMean) || isempty(ob.vmin) || isempty(ob.vmax) )
        return;
      end
      ob.h_bdg.xMean = ob.xMean;
      ob.h_bdg.vmin  = ob.vmin;
      ob.h_bdg.vmax  = ob.vmax;
      
    end % set_working_bdg
    
    function ob = set_fns (ob, the_dir, names)
    % for each tr_info(i), set
    %   .fn_mha, .fn_mk_fg and .fn_mk_bg
      for i = 1 : numel(names)
        nm = names(i);
        ob.tr_info(i).fn_mha   = fullfile(the_dir, nm, 't.mha');
        ob.tr_info(i).fn_mk_fg = fullfile(the_dir, nm, 'maskv3.mha');
        ob.tr_info(i).fn_mk_bg = fullfile(the_dir, nm, 'maskb.mha');
      end % for
    end % set_fns
    
  end % methods 
  
end % bdg_mhaInDir

function st = create_tr_info ()
  st = struct(...
    'fn_mha',   '',... % full file name for mha
    'fn_mk_fg', '',...
    'fn_mk_bg', '',...
    'i_bat',    1);    % current batch count
end

