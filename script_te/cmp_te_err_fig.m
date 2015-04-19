function cmp_te_err_fig()
fn1 = './rst_zoo/tr_tmp4_over_tmp3_te_slices2.fig';
[x1,y1] = get_xy_fig(fn1);

fn2 = './rst_zoo/tr_tmp3_te_slices2.fig';
[x2,y2] = get_xy_fig(fn2);

% show
figure;
hold on;
plot(x1,y1, 'ro-', 'linewidth',2);
plot(x2,y2, 'bx-', 'linewidth',2);
grid on;
hold off;
legend({fn1,fn2}, 'Interpreter','none');

function [x,y] = get_xy_fig(fn_fig)
open(fn_fig);
tmp = findobj(gca,'type','line');
x = get(tmp,'xdata');
y = get(tmp,'ydata');
close(gcf);