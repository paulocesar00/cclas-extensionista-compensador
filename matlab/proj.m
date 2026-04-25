function r = proj(g, e, mf, ent, lento, tipo)
%CCLAS

%% ENTRADA
s = tf('s'); 

try %pro caos do usuario colocar uma planta que nao dê pra parsear
    P = eval(g); %planta
    P = tf(P); %tf
catch
    error('Nao foi possivel ler a planta. Use tipo: 10/(s*(s+1))');
end

ent = lower(string(ent));
lento = lower(string(lento));
tipo = str2double(string(tipo));
K = ganho(P, tipo, e, ent); % Kc

%% 1
A = K * P; 
[~, pm0] = margin(A); %margem

if lento == "sim" %aceita delay na resposta
    [C, modo, par, obs] = lag(P, K, mf);
else
    [C, modo, par, obs] = lead(P, K, mf, pm0);
end

%%CHECK
L = C * P; %aberto
T = feedback(L, 1); %fechado
[gm, pm, ~, wc] = margin(L); %margem dnv
er = erro(L, ent, tipo); %erro

%%SAIDA
r.P = P;
r.C = C;
r.L = L;
r.T = T;
r.K = K;
r.pm0 = pm0;
r.tipo = tipo;
r.modo = modo;
r.par = par;
r.pm = pm;
r.gm = gm;
r.wc = wc;
r.er = er;
r.ent = ent;
r.obs = obs;
r.txt = resumo(r, e, mf);
end

function K = ganho(P, tipo, e, ent)
%%Kc
[num, den] = tfdata(P, 'v');
kg = ganho0(num, den); %ganho

if ent == "degrau"
    if tipo >= 1
        K = 1;
        return
    end

    K = ((1 / e) - 1) / kg;
    K = max(real(K), 1);
    return
end

if tipo == 0
    error('Planta com 0 integradores tem erro infinito para entrada rampa.');
end

if tipo >= 2
    K = 1;
    return
end

K = 1 / (e * kg);
K = max(real(K), 1);
end

function [C, modo, par, obs] = lead(P, K, mf, pm)
%% LEAD
s = tf('s');
A = K * P; 

phi = mf - pm + 5; % fase
if ~isfinite(phi) || phi <= 0
    phi = 5;
end

obs = 'Foi usado compensador LEAD pra aumentar a margem de fase.';

a = (1 + sind(phi)) / (1 - sind(phi)); %fator igual do fabrizio
a_db = 20 * log10(a);
alvo = -10 * log10(a);

w = logspace(-3, 3, 3000); %freq
[mag, ~] = bode(A, w);
mag = squeeze(mag);
db = 20 * log10(mag);

[~, i] = min(abs(db - alvo));
wm = w(i); %meio certinho
w2 = wm / sqrt(a); %zero
w1 = wm * sqrt(a); %polo

C = K * (s / w2 + 1) / (s / w1 + 1);
modo = 'LEAD';
obs = sprintf('%s w2 = %.4g rad/s, w1 = %.4g rad/s.', obs, w2, w1);

par.phi = phi;
par.a = a;
par.a_db = a_db;
par.alvo = alvo;
par.wm = wm;
par.w1 = w1;
par.w2 = w2;
end

function [C, modo, par, obs] = lag(P, K, mf)
%% LAG
s = tf('s');
A = K * P; 

w = logspace(-3, 3, 3000); 
[mag, fase] = bode(A, w);
mag = squeeze(mag);
fase = squeeze(fase);

fase_alvo = -180 + mf + 5; %desejado
[~, i] = min(abs(fase - fase_alvo));
wc_lag = w(i); %onde cruza
M_db = 20 * log10(mag(i));

a = 10 ^ (-M_db / 20); %fator dnv
if a >= 1
    a = 0.1;
end

w2 = wc_lag / 10; % zero
w1 = a * w2; % polo

C = K * (s / w2 + 1) / (s / w1 + 1);
modo = 'LAG';
obs = sprintf('Foi usado compensador LAG porque o usuario aceitou resp mais lenta. w2 = %.4g rad/s, w1 = %.4g rad/s.', w2, w1);

par.fase_alvo = fase_alvo;
par.wc_lag = wc_lag;
par.M_db = M_db;
par.a = a;
par.w1 = w1;
par.w2 = w2;
end

function er = erro(L, ent, tipo)
%% ERRO
[num, den] = tfdata(L, 'v');
kg = ganho0(num, den); % ganho

if ent == "degrau"
    if tipo >= 1
        er = 0;
    else
        er = 1 / (1 + kg);
    end
    return
end

if tipo == 0
    er = inf;
elseif tipo >= 2
    er = 0;
else
    er = 1 / kg;
end
end

function kg = ganho0(num, den)
%% GANHO
while abs(den(end)) < 1e-12
    den(end) = [];
end

kg = num(end) / den(end);
end

function txt = resumo(r, e, mf)
%% RESUMO
c = textoC(r.C);

lin = {
    'RESULTADO'
    '---------'
    sprintf('Compensador: %s', r.modo)
    sprintf('Integradores na planta: %d', r.tipo)
    sprintf('Kc calculado: %.5g', r.K)
    sprintf('MF antes do compensador: %.5g graus', r.pm0)
    sprintf('Erro desejado: %.5g', e)
    sprintf('Erro obtido: %.5g', r.er)
    sprintf('MF desejada: %.5g graus', mf)
    sprintf('MF obtida: %.5g graus', r.pm)
    sprintf('Wc: %.5g rad/s', r.wc)
    ''
    'PARAMETROS DO COMPENSADOR'
    parametros(r)
    ''
    'C(s):'
    c
    ''
    'Observacao:'
    r.obs
    };

txt = strjoin(lin, newline);
end

function txt = parametros(r)
%% PARAMETROS
if r.modo == "LEAD"
    txt = sprintf(['phi = %.5g graus\n' ...
        'a = %.5g\n' ...
        'a_dB = %.5g dB\n' ...
        'alvo = %.5g dB\n' ...
        'wm = %.5g rad/s\n' ...
        'w2 = %.5g rad/s (zero)\n' ...
        'w1 = %.5g rad/s (polo)'], ...
        r.par.phi, r.par.a, r.par.a_db, r.par.alvo, ...
        r.par.wm, r.par.w2, r.par.w1);
else
    txt = sprintf(['fase alvo = %.5g graus\n' ...
        'wc_lag = %.5g rad/s\n' ...
        'M_db = %.5g dB\n' ...
        'a = %.5g\n' ...
        'w2 = %.5g rad/s (zero)\n' ...
        'w1 = %.5g rad/s (polo)'], ...
        r.par.fase_alvo, r.par.wc_lag, r.par.M_db, ...
        r.par.a, r.par.w2, r.par.w1);
end
end

function txt = textoC(C)
%% FORMULA, OBRIGADO POR ESSA PARTE CHATLGPD
[num, den] = tfdata(C, 'v');
n = strtrim(poly2str(num, 's'));
d = strtrim(poly2str(den, 's'));
txt = sprintf('C(s) = (%s) / (%s)', n, d);
end