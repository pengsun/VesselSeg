classdef bdg_matInDir < bdg_i
  %BDG_MATINDIR BDG for mat files 1.mat,...,M.mat in directory
  %   Detailed explanation goes here
  
  properties
    dir_mat; % mat file directory
    matIds;  % [M]. mat files ids
    bs;      % batch size
    
    i_mat;  % the working mat id
    h_bdg;  % the underlying batch data generator
  end
  
  methods % implement the bdg_i interfaces
    
    function ob = bdg_matInDir (dir_mat, matIds, bs)
      ob.dir_mat = dir_mat;
      ob.matIds  = matIds;
      ob.bs      = bs;
      
      ob.i_mat = 0;
    end
    
    function ob = reset_epoch(ob)
      ob = move_toNextMat(ob);
      ob.h_bdg = reset_epoch(ob.h_bdg);
    end
    
    function data = get_bd(ob, i_bat)
      data = get_bd(ob.h_bdg, i_bat);
    end
    
    function data = get_bd_orig(ob, i_bat)
      data = get_bd_orig(ob.h_bdg, i_bat);
    end
    
    function N = get_bdsz(ob, i_bat)
      N = get_bdsz(ob.h_bdg, i_bat);
    end
    
    function nb = get_numbat(ob)
      nb = get_numbat(ob.h_bdg);
    end
    
    function ni = get_numinst (ob)
      ni = get_numinst(ob.h_bdg);
    end
    
  end % method
  
  methods % auxiliary, extra interfaces
    
    function ob = move_toNextMat (ob)
      % circulate over 1,2,...,N
      ob.i_mat = ob.i_mat + 1;
      if ( ob.i_mat > numel(ob.matIds) )
        % shuffle
        ix = randperm( numel(ob.matIds) );
        ob.matIds = ob.matIds(ix);
        ob.i_mat  = 1;
        
        fprintf('new mat order: %d\n', ob.matIds);
      end
      
      % load the corresponding mat file
      fn_mat = [num2str(ob.i_mat),'.mat'];
      ffn_mat = fullfile( ob.dir_mat, fn_mat );
      fprintf('loading new mat %s...', ffn_mat);
      
      t = tic;
      st = load(ffn_mat);
      
      % set the working bdg
      clear ob.h_bdg;
      ob.h_bdg = bdg_memXd4Yd2(st.X, st.Y, ob.bs);      
      %
      t = toc(t);
      fprintf('done. Time spent: %4.3f \n', t);
    end % move_toNextMat
    
  end % auxiliary 

end

