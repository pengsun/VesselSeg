function write_matMhaDir2(fn_info, K,  fn_out, tarSetId)
%WRITE_MATMHADIR Summary of this function goes here
%   fn_info: 
%   K: #instances to write
%   fn_out: output mat
%   tarSetId: 1 tr, 3 te

% init
X = zeros(48,48,3,0, 'single');
Y = zeros(2, 0, 'single');
imgId = [];
pntId = [];
% root directory for the img, mask, etc
dir_root = fileparts(fn_info);

%
load(fn_info, ...
  'imgNames', 'imgSetId',...
  'Xm','vmax','vmin');

% random order
ir = randperm( numel(imgNames) );
imgNames = imgNames(ir);
imgSetId = imgSetId(ir);

% get the **training instances or testing instances only**
if nargin==3
  tarSetId = 1;
end
tarId = (imgSetId==tarSetId);
for i = 1 : numel(tarId)
  if ( ~tarId(i) ), continue; end
  
  nm = imgNames{i};
  fprintf('processing %s...', nm);
  
  % the mha 
  fn_mha   = fullfile(dir_root, nm, 't.mha');      % uncompressed volume
  fn_mk_fg = fullfile(dir_root, nm, 'maskv3.mha'); % Aorta removed
  fn_mk_bg = fullfile(dir_root, nm, 'maskb.mha');  % background!
  
  % generate instance & labels
  is_cont = false;
  try 
    [xx, yy, ind] = gen_mat2(fn_mha, fn_mk_fg, fn_mk_bg, K);
  catch
    is_cont = true;
  end
  
  if (is_cont)
    fprintf('error occured, skip this\n');
    continue; 
  end
  
  % preprocessing: to 0 mean, approximately [-1, +1]
  [xx, yy] = deal( single(xx), single(yy) );
  xx = bsxfun(@minus, xx, Xm);
  ix      = (xx > 0);
  xx(ix)  = xx(ix)  ./ abs(vmax);
  xx(~ix) = xx(~ix) ./ abs(vmin); 
  
  % concatenate
  X = cat(4, X, xx);
  Y = cat(2, Y, yy);
  
  % the image id
  N = size(yy,2); assert(N==size(xx,4));
  imgId = [imgId(:); ir(i)*ones(N,1)];
  
  % the point id
  pntId = [pntId(:); ind(:)];
  
  fprintf('done\n');
end

% write to file
fprintf('writing %s...', fn_out);
save(fn_out, ...
  'X','Y', 'imgId', 'pntId',...
  '-v7.3');
fprintf('done\n');
