%get_y_g27s2 Get 27 dim labels. Each elem: 0/1 bg/fg response. Stride 2.
%   yy = get_y_g27s2(mk, ind)
%   mk: [a,b,c]. 255: vessels, 128: background, 0: not interested
%   ind: [M] linear index to the mk
%   yy: [27, M] each elem, 0/1 bg/fg response
