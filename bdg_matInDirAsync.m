classdef bdg_matInDirAsync < bdg_i
  %BDG_MATINDIRASYNC BDG for mat files 1.mat,...,M.mat in dir with
  %prefetching by parfeval (asyncronous IO)
  %   TODO: checking when loading current mat
  %   TODO: prefetching when switching to new super epoch
  
  properties
    dir_mat; % mat file directory
    matIds;  % [M]. mat files ids
    nPerMat; % [1]. #used per mat
    bs;      % batch size
    
    i_mat; % the working mat id
    c_mat; % counting per mat
    h_bdg; % the underlying batch data generator
    ff;    % Matlab parallel.future, for mat loading task
  end
  
  methods % implement the bdg_i interfaces
    
    function ob = bdg_matInDirAsync (dir_mat, matIds, nPerMat, bs)
      ob.dir_mat = dir_mat;
      ob.matIds  = matIds;
      ob.nPerMat = nPerMat;
      ob.bs      = bs;
      
      ob.i_mat = numel(ob.matIds);
      ob.c_mat = ob.nPerMat + 1;
    end
    
    function ob = reset_epoch(ob)
      ob = prepare_matForCurEpoch(ob);
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
    
    function ob = prepare_matForCurEpoch (ob)
      % in one super epoch, circulate over 
      % 1,..,1, 2,..,2,...,N,...,N, where
      % each mat is repeated ob.nPerMat times
      
      if ( ob.c_mat < ob.nPerMat) % still use current mat
        ob.c_mat = ob.c_mat + 1;
        return;
      end
      
      ob.i_mat = ob.i_mat + 1; % use the new mat ...
      ob.c_mat = 1;            % ...for the first time
      
      % begin a new super epoch ?
      if ( ob.i_mat > numel(ob.matIds) )
        ob = init_superEpoch(ob);
      end
      
      % load the corresponding mat file from buffer
      % should be ready or almost ready
      ob = fetch_cur_mat(ob);
      
      % need prefetching ?
      i_nextMat = ob.i_mat + 1;
      if (i_nextMat > numel(ob.matIds) ), return; end
      
      % prefetch the next mat
      ob = prefetch_mat(ob, i_nextMat);
    end % prepare_matForCurEpoch
    
    function ob = init_superEpoch (ob)
      % prepare the mat order
      ix = randperm( numel(ob.matIds) ); % shuffle
      ob.matIds = ob.matIds(ix);
      fprintf('begin a new super eopch with mat order: %d\n', ob.matIds);
      % initial states
      ob.i_mat = 1;
      ob.c_mat = 1; 
      % begin prefetching
      ob = prefetch_mat(ob, ob.i_mat);
    end % init_superEpoch
    
    function ob = prefetch_mat(ob, cnt)
      fn_mat  = [num2str( ob.matIds(cnt) ), '.mat'];
      fprintf('begin prefetching mat %s...\n', fn_mat);
      ffn_mat = fullfile( ob.dir_mat, fn_mat );
      
      ob.ff = parfeval( @load_xy_, 2, ffn_mat);
    end % prefetch_mat
    
    function ob = fetch_cur_mat(ob)
      fprintf('loading mat %d from buffer...', ob.matIds(ob.i_mat));
      t = tic; % ---------------------------
      [X,Y] = fetchOutputs(ob.ff);
      % set the working bdg
      clear ob.h_bdg;
      ob.h_bdg = bdg_memXd4Yd2(X, Y, ob.bs);      
      t = toc(t); % ------------------------
      fprintf('done. Time spent: %4.3f \n', t);
    end % fetch_cur_mat
    
  end % auxiliary 

end 

function [X,Y] = load_xy_ (fn)
  tmp = load(fn);
  X = tmp.X;
  Y = tmp.Y;
end