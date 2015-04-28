%% config
opt = {};
% opt{end+1} = '-g';
opt{end+1} = '-v';
opt{end+1} = '-largeArrayDims';
% opt{end+1} = '-DVB';

str = computer('arch');
switch str(1:3)
  case 'win' 
    opt{end+1} = 'COMPFLAGS=/openmp $COMPFLAGS';
    opt{end+1} = 'LINKFLAGS=/openmp $LINKFLAGS';
  otherwise
    opt{end+1} = 'CXXFLAGS="\$CXXFLAGS -fopenmp -std=c++11"';
    opt{end+1} = 'LDFLAGS="\$LDFLAGS -fopenmp -std=c++11"';
end
%% do it
mex(opt{:}, 'load_xy_async.cpp');
mex(opt{:}, 'get_x_3slices.cpp');
mex(opt{:}, 'get_y_g27s2.cpp');
% mex(opt{:}, 'toy.cpp');