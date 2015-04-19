function yy = get_y_cen(mk, ind)
%get_y_cen Get vector-valued labels from the mask
%   mk: [a,b,c]. 255: vessels, 128: background, 0: not interested
%   ind: [M] index to the mk
%   yy: [2, M] 0/1 vector-valued response

  % values from the mask
  v = mk(ind);
  M = numel(ind);
  
  % scalr to vector response
  yy = zeros(2, M, 'single');
  yy(2, v==255) = 1; % fore ground
  yy(1, v==128) = 1; % back ground
end

