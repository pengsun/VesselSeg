%% config
N = 3; % avoid the 1-instance pitfall 
sz = [48, 48, 3, N];

T = 1000; % #iterations
mu = 0.01;
lambda = 0.001;

% mu = 0.01;
% lambda = 0.005;

% from old code
% mu = 0.0005;
% lambda = 0.005;
%% get the mean, vmin, vmax
load('C:\Temp\slices2.mat', 'Xm','vmin','vmax');
%% load the trained model
load('.\mo_zoo\slices2_over_tmp4_over_tmp3\ep_900.mat');
h = ob.the_dag;
%% Specify the label
y = zeros(2,N, 'single');
y(2,:) = 1; %
y = gpuArray(y);
%% initialize I
I = zeros(sz, 'single');
I = gpuArray(I);
%% iterate and update I
% prepare
cc = call_cntxt();
cc.is_tr = false;
cc.epoch_cnt = 1;
h = set_cc(h, cc);

for t = 1 : T
  fprintf('iter = %d, ', t);
  
  % set the context
  cc.iter_cnt = t;
  
  % set the input data for the source nodes
  h.i(1).a = I;
  h.i(2).a = 0.0; % OK with a trash scalar label
  
  h.tfs{1}.i.a      = h.ab.cvt_data( h.i(1).a ); % bat_X
  h.tfs{end}.i(2).a = h.ab.cvt_data( h.i(2).a ); % bat_Y
  
  % fprop except for the last tf (the loss)
  M = numel(h.tfs) - 1;
  for i = 1 : M
    h.tfs{i} = fprop(h.tfs{i});
    h.ab.sync();
  end
  
  % enforce the class score!
  h.tfs{M}.o.d = reshape(y, [1,1,size(y,1),size(y,2)]);
  % bprop except for the last tf (the loss)
  for i = M : -1 : 1
    h.tfs{i} = bprop(h.tfs{i});
    h.ab.sync();
  end
  h.i(1).d = h.tfs{1}.i.d; % bat_X
  
  % get the gradient for the input image
  g = h.i(1).d - 2*lambda*I;
  
  % update
  I = I + mu*g;
  
  % info
  tmp = I(:,:,:,1);
  fprintf('avg norm = %d\n', norm(tmp(:))./numel(tmp(:)) );
end
%% fetch to main memory
I = gather(I);
II= I(:,:,:,1);
%% restore to int16 dynamic range
% II( II>0 ) = vmax * II(II>0);
% II( II<0 ) = abs(vmin) * II(II<0);
% II = II + Xm;
%% plot
figure;
subplot(1,3,1), imshow(II(:,:,1), []);
subplot(1,3,2), imshow(II(:,:,2), []);
subplot(1,3,3), imshow(II(:,:,3), []);
%%
% %% fetch to main memory
% I = gather(I);
% Ibg = I(:,:,:,1);
% Ifg = I(:,:,:,2);
% %% restore to int16 dynamic range
% % II( II>0 ) = vmax * II(II>0);
% % II( II<0 ) = abs(vmin) * II(II<0);
% % II = II + Xm;
% %% plot
% figure;
% subplot(2,3,1), imshow(Ibg(:,:,1), []);
% subplot(2,3,2), imshow(Ibg(:,:,2), []);
% subplot(2,3,3), imshow(Ibg(:,:,3), []);
% 
% subplot(2,3,4), imshow(Ifg(:,:,1), []);
% subplot(2,3,5), imshow(Ifg(:,:,2), []);
% subplot(2,3,6), imshow(Ifg(:,:,3), []);