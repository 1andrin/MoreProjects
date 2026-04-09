% run_hd.m  –  Run BVAR historical decomposition
% Edit the settings below, then press Run (▶) or press F5.

%% ---- USER SETTINGS -------------------------------------------------------
data_file  = 'data.csv';       % CSV filename (must be in the same folder)
target_var = 'ch_food_cpi';    % variable to decompose (must match a column name)
%% --------------------------------------------------------------------------

%% 1. Path setup
bear_lite_dir = fileparts(mfilename('fullpath'));
addpath(bear_lite_dir)

%% 2. Load data
[endo, varnames, dates] = bear_load_csv(fullfile(bear_lite_dir, data_file));

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

%% 6. Export HD results to CSV for Python plotting
i_target = find(strcmp(varnames, target_var));
if isempty(i_target)
    warning('target_var ''%s'' not found in varnames – skipping export.', target_var);
else
    T_eff = results.T;                     % effective sample length (lags trimmed)
    n     = results.n;

    % Median shock contributions for the target variable (T_eff x n matrix)
    hd_mat = zeros(T_eff, n);
    for j = 1:n
        hd_mat(:, j) = results.hd_estimates{j, i_target}(2, :)';
    end

    % Align dates: olsvar drops the first s.lags rows from the front
    dates_eff = dates(s.lags + 1 : s.lags + T_eff);

    % Write CSV:  date | var1 | var2 | ... | varn
    hd_table = array2table(hd_mat, 'VariableNames', varnames);
    hd_table = addvars(hd_table, dates_eff, 'Before', 1, 'NewVariableNames', 'date');

    export_path = fullfile(bear_lite_dir, 'hd_results.csv');
    writetable(hd_table, export_path);
    fprintf('HD results exported to: %s\n', export_path);
end
