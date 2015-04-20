%acc_y_g27s2 Accumulate the 27 dim predictions. Stride 2.
%   img = acc_y_g27s2(img, ind, y)
%   Input:
%   img: [a,b,c]. single. the heat map
%   ind: [M] linear index to the img
%   y: [27, M] each elem, a bg/fg response. The bigger, the more likely
%   fg.
%   Output:
%   img: in place accumulation
