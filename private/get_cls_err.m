function [err, err_one, err_two] = get_cls_err(Ypre, Y)

% the error
[~, label_pre] = max(Ypre,[], 1);
[~, label]     = max(Y,[],    1);
N = numel(label);
err = sum( label_pre ~= label ) / N;

% the class 1 error
one_pre = ( Ypre(1,:) > Ypre(2,:) );
one_gt  = ( Y(1,:) > Y(2,:) );
a_one = sum( one_gt & one_pre ) ./ (sum(one_gt)+eps);
err_one = 1 - a_one;

% the class 2 error
two_pre = (Ypre(2,:) > Ypre(1,:));
two_gt  = (Y(2,:) > Y(1,:));
a_two = sum( two_gt & two_pre ) ./ (sum(two_gt)+eps);
err_two = 1 - a_two; 