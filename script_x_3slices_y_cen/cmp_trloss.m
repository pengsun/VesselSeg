%%
fn1 = 'D:\CodeWork\git\VesselSeg\mo_zoo\tmp4\ep_150.mat';
load(fn1);
y1 = ob.L_tr;
clear ob;
%%
fn2 = 'D:\CodeWork\git\VesselSeg\mo_zoo\tmp4_over_tmp3\ep_700.mat';
load(fn2);
y2 = ob.L_tr(501:700);
clear ob;
%%
figure;
hold on;
plot(y1, 'ro-', 'linewidth',2);
plot(y2, 'bx-', 'linewidth',2);
set(gca,'yscale','log');
grid on;
hold off;
legend({fn1,fn2}, 'Interpreter','none');