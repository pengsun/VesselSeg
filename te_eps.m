function [err_ep, err] =  te_eps(varargin)

% config 
% TODO: add more properties here
if ( nargin==0 )
  ep = 500 : 500;
  batch_sz = 64;
  dir_mo = fullfile('.\');
  fn_data = fullfile('C:\Dev\code\VesselSeg\tmp3.mat');
  fn_mo_tmpl = 'ep_%d.mat';
elseif ( nargin==5 )
  ep = varargin{1};
  batch_sz = varargin{2};
  dir_mo = varargin{3};
  fn_data = varargin{4};
  fn_mo_tmpl = varargin{5};  
else
  error('Invalid arguments.');
end

% load data
te_bdg = load_te_data(fn_data, batch_sz);

% print
fprintf('data: %s\n', fn_data);

% plot
err_ep = 0;
err = 1;
figure;
hax = axes;
title(dir_mo);
plot_err(hax, err_ep, err);

for i = 1 : numel(ep)
  % init dag: from file 
  fn_mo = sprintf(fn_mo_tmpl, ep(i));
  ffn_mo = fullfile(dir_mo, fn_mo);
  if ( ~exist(ffn_mo,'file') )
    fprintf('%s not found, break and stop.\n', ffn_mo);
    break; 
  end
  load(ffn_mo, 'ob');
  % get ob from here
 
  Ypre = test(ob, te_bdg);
  Ypre = gather(Ypre);

  % show the error
  err(1+i) = get_cls_err(Ypre, te_bdg.Y);
  err_ep = [err_ep, ep(i)];
  plot_err(hax, err_ep, err)
  legend({fn_mo}, 'Interpreter','none' )
  
  % print the error
  fprintf('model: %s\n', fn_mo);
  fprintf('classification error = %d\n', err(end) );
end
title(fn_data);


function te_bdg = load_te_data(fn_data, bs)
load(fn_data, 'X','Y','setId');
ind_te = find( setId == 3 );

xx = X(:,:,:, ind_te);
yy = Y(:, ind_te);

te_bdg = bdg_memXd4Yd2(xx,yy, bs);

function err = get_cls_err(Ypre, Y)
[~, label_pre] = max(Ypre,[], 1);
[~, label]     = max(Y,[],    1);
N = numel(label);
err = sum( label_pre ~= label ) / N;

function plot_err(hax, err_ep, err)
plot(err_ep, err, 'ro-', 'linewidth', 2, 'parent', hax);
xlabel('epoches');
ylabel('testing classification error');
% set(hax, 'yscale','log');
grid on;
drawnow;