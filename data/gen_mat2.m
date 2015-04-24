function [xx, yy, ind] = gen_mat2(fn_mha, fn_mk_fg, fn_mk_bg, KK)
%GEN_MAT Summary of this function goes here
%   xx: [48,48,3,M]
%   yy: [2, M]
%   ind: [M]
  mha   = mha_read_volume(fn_mha);
  mk_fg = mha_read_volume(fn_mk_fg);
  mk_bg = mha_read_volume(fn_mk_bg);
 
  assert( all(size(mha)==size(mk_fg)) );
  assert( all(size(mk_fg)==size(mk_bg)) );
  
  % combine fg, bg mask to make a single one
  mk_fgbg = mk_fg;
  itmp = (mk_bg==255);
  mk_fgbg(itmp) = 128;
  
  % randomly sample K1
  K1 = floor(KK/2);
  ix_fg = find(mk_fg == 255);
  ind1  = ix_fg( randsample(numel(ix_fg), K1) );
  
  % randomly sample K2
  K2 = ceil(KK/2);
  ix_bg = find(mk_bg == 255);
  ind2 = ix_bg( randsample(numel(ix_bg), K2) );
  
  % the balanced sampling
  ind = [ind1(:); ind2(:)];
  tmp = randperm( numel(ind) );
  ind = ind(tmp);
  
  % get the instances and labels
  xx = single( get_x_3slices(mha, ind) );
  yy = single( get_y_cen(mk_fgbg, ind) );
end

