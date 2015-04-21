function [xx, yy, ind] = gen_mat(fn_mha, fn_mk_fg, fn_mk_bg, KK)
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
  
  % randomly sample KK
  ix_fgbg = find(mk_fgbg > 0);
  ind = ix_fgbg( randsample(numel(ix_fgbg), KK) );
  tmp = randperm( numel(ind) );
  ind = ind(tmp);
  
  % 
  xx = single( get_x_3slices(mha, ind) );
  yy = single( get_y_cen(mk_fgbg, ind) );
end

