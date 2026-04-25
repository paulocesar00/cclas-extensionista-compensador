function plota(r, ax1, ax2, ax3, ax4, ax5)
%bode e resp

%% DADOS
w = logspace(-3, 3, 1000); %freq
A = r.K * r.P; %antes
L = r.L; %depois

[m1, f1] = bode(A, w);
[m2, f2] = bode(L, w);
m1 = squeeze(m1);
m2 = squeeze(m2);
f1 = squeeze(f1);
f2 = squeeze(f2);

%% BODE COMPARADO
cla(ax1)
semilogx(ax1, w, 20 * log10(m1), '--', w, 20 * log10(m2), 'LineWidth', 1.2)
grid(ax1, 'on')
ax1.XMinorGrid = 'off'; %bugado se aumenta a janela sem aumentar os ticks no X
title(ax1, 'Bode - magnitude')
xlabel(ax1, 'rad/s')
ylabel(ax1, 'dB')
legend(ax1, 'K*P(s)', 'C(s)*P(s)', 'Location', 'best')
eixo(ax1)

cla(ax2)
semilogx(ax2, w, f1, '--', w, f2, 'LineWidth', 1.2)
grid(ax2, 'on')
ax2.XMinorGrid = 'off';
title(ax2, 'Bode - fase')
xlabel(ax2, 'rad/s')
ylabel(ax2, 'graus')
legend(ax2, 'K*P(s)', 'C(s)*P(s)', 'Location', 'best')
eixo(ax2)

%% TEMPO
t = linspace(0, 10, 1000);
cla(ax3)

if r.ent == "rampa"
    u = t;
    y = lsim(r.T, u, t);
    plot(ax3, t, u, '--', t, y, 'LineWidth', 1.2)
    legend(ax3, 'referencia', 'saida', 'Location', 'best')
    title(ax3, 'Resposta a rampa')
else
    y = step(r.T, t);
    plot(ax3, t, ones(size(t)), '--', t, y, 'LineWidth', 1.2)
    legend(ax3, 'referencia', 'saida', 'Location', 'best')
    title(ax3, 'Resposta ao degrau')
end

grid(ax3, 'on')
xlabel(ax3, 'tempo (s)')
ylabel(ax3, 'amplitude')

%% BODE FINAL FINAL MESMO
if nargin >= 5 && ~isempty(ax4)
    cla(ax4)
    semilogx(ax4, w, 20 * log10(m2), 'LineWidth', 1.2)
    grid(ax4, 'on')
    ax4.XMinorGrid = 'off';
    title(ax4, 'Bode final - magnitude')
    xlabel(ax4, 'rad/s')
    ylabel(ax4, 'dB')
    hold(ax4, 'on')
    xline(ax4, r.par.w1, '--', 'w1')
    xline(ax4, r.par.w2, '--', 'w2')
    hold(ax4, 'off')
    eixo(ax4)
end

if nargin >= 6 && ~isempty(ax5)
    cla(ax5)
    semilogx(ax5, w, f2, 'LineWidth', 1.2)
    grid(ax5, 'on')
    ax5.XMinorGrid = 'off';
    title(ax5, 'Bode final - fase')
    xlabel(ax5, 'rad/s')
    ylabel(ax5, 'graus')
    hold(ax5, 'on')
    xline(ax5, r.par.w1, '--', 'w1')
    xline(ax5, r.par.w2, '--', 'w2')
    hold(ax5, 'off')
    eixo(ax5)
end
end

function eixo(ax)
%% EIXO
ax.XScale = 'log';
ax.XLim = [1e-3 1e3];
ax.XTick = 10 .^ (-3:3);
end