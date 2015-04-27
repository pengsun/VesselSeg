classdef bdg_mha < bdg_i
  %BDG_MHA Batch Data Generator, load MHA and mask files
  %   X: [48,48,3,N], ndims(X) = 4
  %   Y: [2,N], each clumn, [1;0] is bg, [0;1] is fg 
  
  properties
    mha;     % [a,b,c] the 3d CT volume
    mk_fgbg; % [a,b,c] the mask:
             % 255: vessels, 128: background, 0: not interested
    
    ix_fgbg; % [M] # fg+bg pixels index
    
    hb; % handle to a  bat_gentor
  end
  
  properties % to restore
    xMean; % [48, 48, 3] int16 mean image
    vmax;  % [1] int16 max value
    vmin;  % [1] int16 min value
  end
  
  methods % implement the bdg_i interfaces
    function ob = bdg_mha (mha, mk_fg, mk_bg, bs)
      %
      assert( all(size(mha)==size(mk_fg)) );
      assert( all(size(mk_fg)==size(mk_bg)) );
      
      % restore the main CT volume
      ob.mha = mha;
      
      % construct the internal mask
      ob.mk_fgbg = mk_fg;
      itmp = (mk_bg==255);
      ob.mk_fgbg(itmp) = 128;
      
      % create internal batch generator
      ob.ix_fgbg = find(ob.mk_fgbg > 0);
      N = numel(ob.ix_fgbg);
      ob.hb = bat_gentor();
      ob.hb = reset(ob.hb, N,bs);
    end 
    
    function ob = reset_epoch(ob)
    % reset for a new epoch
      N = numel(ob.ix_fgbg);
      bs = get_bdsz(ob, 1);
      ob.hb = reset(ob.hb, N,bs);
    end
    
    function data = get_bd (ob, i_bat)
    % get the i_bat-th batch data
      error('not implemented');
      
%       idx = get_idx(ob.hb, i_bat);
%       data{1} = ob.X(:,:,:,idx);
%       data{2} = ob.Y(:,idx);
    end
    
    function data = get_bd_orig (ob, i_bat)
    % get the i_bat-th batch data
      % the instance index
      idx = get_idx_orig(ob.hb, i_bat);
      % the fg, bg mask index: should never be out of boundary
      ind_fgbg = ob.ix_fgbg(idx);
      
      % the instaces: X
      X = get_x_3slices(ob.mha, ind_fgbg);
      data{1} = restore_X(ob, X);
      % the labels: Y
      data{2} = get_y_cen(ob.mk_fgbg, ind_fgbg);
      
%       %the instaces: X
%       X = get_3slices(ob.mha, ind_fgbg);
%       data{1} = restore_X(ob, X);
%       % the labels: Y
%       data{2} = get_labels(ob.mk_fgbg, ind_fgbg);
    end
    
    function N = get_bdsz (ob, i_bat)
    % get the size of the i_bat-th batch data
      N = numel( get_idx_orig(ob.hb, i_bat) );
    end
    
    function nb = get_numbat (ob)
    % get number of batchs in an epoch
      nb = ob.hb.num_bat;
    end
    
    function ni = get_numinst (ob)
    % get number of the total instances
      ni = numel(ob.ix_fgbg);
    end
  end % methods
  
  methods % auxiliary, extra interfaces
    
    function Ygt = get_all_Ygt (ob)
      Ygt = get_y_cen(ob.mk_fgbg, ob.ix_fgbg);
    end
    
    function xx = restore_X (ob, x)
      xx = single(x);
      
      if ( isempty(ob.xMean) || isempty(ob.vmin) || isempty(ob.vmax) )
        return;
      end
      
      % to 0 mean, approximately [-1, +1]
      xx = bsxfun(@minus, xx, ob.xMean);
      ix = (xx > 0);
      xx(ix)  = xx(ix) ./ abs(ob.vmax);
      xx(~ix) = xx(~ix) ./ abs(ob.vmin); 
    end % restore_X
    
  end % auxiliary 
  
end % bdg_mha

