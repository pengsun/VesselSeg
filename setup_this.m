%% config
dir_matconvnet = 'C:\Dev\code\psmatconvnet';
dir_matconvdag = 'C:\Dev\code\MatConvDAG';
%% matconvnet
run( fullfile(dir_matconvnet, 'matlab\vl_setupnn') );
%% matconvDAG
tmp = fileparts( mfilename('fullpath') );
cd( fullfile(dir_matconvdag, 'core') );
eval( 'dag_path.setup' );
cd(tmp);
%% this
% root
dir_this = fileparts( mfilename('fullpath') );
addpath( pwd );
% % util
% addpath( fullfile(pwd, 'util') );
% % cache
% addpath( fullfile(pwd, 'cache') );
% % mex
% addpath( fullfile(pwd, 'mex') );
