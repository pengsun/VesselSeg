function X = get_3slices(img, ind)
%GET_3SLICES Summary of this function goes here
%   img: [a,b,c]. the CT volume
%   ind: [M]. linear index to the image for the locations of sampling
%   points
%   X: [48, 48, 3, M]. the slices data batch
%   
  
  % initialize
  hsz = 24;
  sz  = [2*hsz, 2*hsz, 3, numel(ind)];
  X   = zeros(sz, 'like',img);
  
  % fill the data
  [amax,bmax,cmax]    = size(img);
  [ind_a,ind_b,ind_c] = ind2sub(size(img), ind);
  for i = 1 : numel(ind)
    [ia,ib,ic] = deal(ind_a(i), ind_b(i), ind_c(i)); 
    
    a_ran = ia-hsz+1 : ia+hsz;
    a_ran = clap_sz(a_ran, amax);
    
    b_ran = ib-hsz+1 : ib+hsz;
    b_ran = clap_sz(b_ran, bmax);
    
    c_ran = ic-hsz+1 : ic+hsz;
    c_ran = clap_sz(c_ran, cmax);
    
    X(:,:,1, i) = img( a_ran, b_ran, ic);
    X(:,:,2, i) = img( ia, b_ran, c_ran);
    X(:,:,3, i) = img( a_ran, ib, c_ran);
  end
  
end % get_3slices

function ind = clap_sz(ind, sz)
  ind(ind<1) = 1;
  ind(ind>sz) = sz;
end