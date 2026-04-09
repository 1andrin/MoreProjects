% run_hd.m  –  Run BVAR historical decomposition
% Edit the settings below, then press Run (▶) or press F5.

%% 1. Path setup
addpath(fileparts(mfilename('fullpath')))   % adds bear_lite itself

%% 2. Load data
bear_lite_dir = fileparts(mfilename('fullpath'));
[endo, varnames] = bear_load_csv(fullfile(bear_lite_dir, 'data.csv'));

%% 3. Settings
s         = bear_settings();
s.prior   = 11;    % Minnesota (univariate AR sigma)
s.IRFt    = 2;     % Cholesky identification
s.lags    = 4;
s.It      = 2000;
s.Bu      = 1000;

%% 4. Run
results = bear_run(s, endo);

%% 5. Print median HD contributions at each period
n = results.n;
fprintf('\n=== Median HD contributions (shock -> variable) ===\n');
for i = 1:n
    for j = 1:n
        med = results.hd_estimates{j, i}(2, :);   % 1-by-T median
        fprintf('Shock %-10s -> Var %-10s  [mean over sample: %+.4f]\n', ...
            varnames{j}, varnames{i}, mean(med));
    end
end

fprintf('\nDone. Full results are in the ''results'' workspace variable.\n');
