function results = bear_run(settings, data_endo, data_exo)
% BEAR_RUN  Run a standard BVAR and return the historical decomposition.
%
%   RESULTS = BEAR_RUN(SETTINGS, DATA_ENDO) estimates a BVAR using
%   endogenous data only. SETTINGS is a struct from bear_settings().
%   DATA_ENDO is a T-by-n matrix of endogenous variables (rows = time,
%   columns = variables). T must be large enough to accommodate 'lags'.
%
%   RESULTS = BEAR_RUN(SETTINGS, DATA_ENDO, DATA_EXO) additionally
%   includes exogenous variables. DATA_EXO is a T-by-m matrix of
%   contemporaneous exogenous variables aligned with DATA_ENDO.
%   Do not include a constant column; set settings.const=1 instead.
%
%   OUTPUTS  (fields of the returned struct RESULTS):
%
%     hd_estimates  - Historical decomposition. Cell array of size
%                     (C+2)-by-n, where C = n + 1 + has_exo contributors:
%                       rows 1..n      : contribution of shock j to var i
%                       row  n+1       : initial conditions
%                       row  n+2       : constant (when settings.const=1)
%                       row  n+3       : exogenous (when DATA_EXO given)
%                       row  C+1       : unexplained (if model not fully identified)
%                       row  C+2       : portion left for structural shocks
%                     Each cell is a 3-by-T matrix [lower; median; upper]
%                     with band controlled by settings.HDband.
%
%     beta_median   - Posterior median of VAR coefficients, k-by-n matrix.
%     sigma_median  - Posterior median of residual covariance, n-by-n.
%     n, m, p, T, k - Model dimensions after lag trimming.
%     endo_labels   - n-by-1 cell array {'var1',...,'varn'}.
%     exo_labels    - m-by-1 cell array {'exo1',...,'exom'} (may be empty).
%
%   ADDING TO PATH:  Add ONLY the bear_lite folder to your MATLAB path:
%     addpath('/path/to/tbx/bear_lite')
%   Do NOT add tbx/bear alongside bear_lite to avoid namespace conflicts.
%
%   EXAMPLE:
%     s = bear_settings();
%     s.prior = 11;   % Minnesota prior
%     s.IRFt  = 2;    % Cholesky identification
%     s.lags  = 2;    % 2 lags
%     data = randn(100, 3);
%     r = bear_run(s, data);
%     % r.hd_estimates{1,1}(2,:) = median contribution of shock 1 to var 1
%
%   SUPPORTED PRIORS:  11, 12, 13, 21, 22, 31, 32, 41, 51
%   SUPPORTED IRFt:    1 (unrestricted), 2 (Cholesky), 3 (triangular)

if nargin < 3
    data_exo = [];
end

%% -----------------------------------------------------------------------
%  Validate inputs
%% -----------------------------------------------------------------------

if ~isnumeric(data_endo) || ndims(data_endo) ~= 2
    error('bear_run:InvalidData', 'DATA_ENDO must be a 2-D numeric matrix.');
end
if ~isempty(data_exo) && size(data_exo, 1) ~= size(data_endo, 1)
    error('bear_run:DimMismatch', ...
        'DATA_EXO must have the same number of rows as DATA_ENDO.');
end
if ~ismember(settings.prior, [11 12 13 21 22 31 32 41 51])
    error('bear_run:InvalidPrior', ...
        'Unsupported prior=%d. Supported: 11,12,13,21,22,31,32,41,51.', ...
        settings.prior);
end
if ~ismember(settings.IRFt, [1 2 3])
    error('bear_run:InvalidIRFt', ...
        'Unsupported IRFt=%d. Supported: 1 (unrestricted), 2 (Cholesky), 3 (triangular).', ...
        settings.IRFt);
end

%% -----------------------------------------------------------------------
%  Unpack settings
%% -----------------------------------------------------------------------

prior      = settings.prior;
IRFt       = settings.IRFt;
IRFperiods = settings.IRFperiods;
It         = settings.It;
Bu         = settings.Bu;
lags       = settings.lags;
const      = settings.const;
ar         = settings.ar;
lambda1    = settings.lambda1;
lambda2    = settings.lambda2;
lambda3    = settings.lambda3;
lambda4    = settings.lambda4;
lambda5    = settings.lambda5;
lambda6    = settings.lambda6;
lambda7    = settings.lambda7;
lambda8    = settings.lambda8;
bex        = settings.bex;
scoeff     = settings.scoeff;
iobs       = settings.iobs;
lrp        = settings.lrp;
HDband     = settings.HDband;
cband      = settings.cband;

%% -----------------------------------------------------------------------
%  Build variable labels (used in HD cell array row annotations)
%% -----------------------------------------------------------------------

n_vars = size(data_endo, 2);

endo = arrayfun(@(i) sprintf('var%d', i), (1:n_vars)', 'UniformOutput', false);

if isempty(data_exo)
    exo = {};
else
    n_exo_vars = size(data_exo, 2);
    exo = arrayfun(@(i) sprintf('exo%d', i), (1:n_exo_vars)', 'UniformOutput', false);
end

%% -----------------------------------------------------------------------
%  Minimal FAVAR and strctident structs (all features disabled)
%  – required by irfchol, irftrig, hdecomp_inc_exo, hdestimates_inc_exo
%% -----------------------------------------------------------------------

favar.FAVAR    = 0;
favar.HDplot   = 0;
favar.IRFplot  = 0;
favar.FEVDplot = 0;

strctident.strctident           = 0;
strctident.signreslabels_shocks = {};

%% -----------------------------------------------------------------------
%  Block 1: OLS estimates
%  Returns model dimensions (n, m, p, T, k, q) and data matrices (Y, X)
%% -----------------------------------------------------------------------

[Bhat, betahat, sigmahat, X, ~, Y, y, ~, ~, n, m, p, T, k, q] = ...
    bear.olsvar(data_endo, data_exo, const, lags);

%% -----------------------------------------------------------------------
%  Build prior hyperparameter arrays (now that m is known)
%% -----------------------------------------------------------------------

% AR coefficient vector: scalar -> n-by-1
if isscalar(ar)
    ar_vec = repmat(ar, n, 1);
else
    ar_vec = ar(:);
end

% AR residual variances (for prior hyperparameters)
[arvar] = bear.arloop(data_endo, const, p, n);

% lambda4 as n-by-m matrix (all entries equal the scalar setting value)
if isscalar(lambda4)
    lambda4_mat = repmat(lambda4, n, m);
else
    lambda4_mat = lambda4;
end

% priorexo: n-by-m zeros (no individual exogenous priors)
priorexo = zeros(n, m);

% blockexo: empty (block exogeneity not supported via this interface)
blockexo = [];

% H: empty (long-run prior matrix not supported via this interface)
H = [];

%% -----------------------------------------------------------------------
%  Block 2: Dummy observation extension
%  Augments Y and X with sum-of-coefficients / initial-observation dummies
%% -----------------------------------------------------------------------

[Ystar, ystar, Xstar, Tstar, ~, ~, ~, ~] = ...
    bear.gendummy(data_endo, data_exo, Y, X, n, m, p, T, const, ...
                  lambda6, lambda7, lambda8, scoeff, iobs, lrp, H);

%% -----------------------------------------------------------------------
%  Block 3: Prior setup and Gibbs sampler
%% -----------------------------------------------------------------------

if prior == 11 || prior == 12 || prior == 13
    % Minnesota prior -------------------------------------------------
    [beta0, omega0, sigma] = bear.mprior(ar_vec, arvar, sigmahat, ...
        lambda1, lambda2, lambda3, lambda4_mat, lambda5, ...
        n, m, p, k, q, prior, bex, blockexo, priorexo);
    [betabar, omegabar] = bear.mpost(beta0, omega0, sigma, Xstar, ystar, q, n);
    [beta_gibbs, sigma_gibbs] = bear.mgibbs(It, Bu, betabar, omegabar, sigma, q);
    [beta_median, ~, ~, ~, sigma_median] = ...
        bear.mestimates(betabar, omegabar, sigma, q, cband);

elseif prior == 21 || prior == 22
    % Normal-Wishart prior --------------------------------------------
    [B0, beta0, phi0, S0, alpha0] = bear.nwprior(ar_vec, arvar, ...
        lambda1, lambda3, lambda4_mat, n, m, p, k, q, prior, priorexo); %#ok<ASGLU>
    [~, betabar, phibar, Sbar, alphabar, alphatilde] = ...
        bear.nwpost(B0, phi0, S0, alpha0, Xstar, Ystar, n, Tstar, k);
    [beta_gibbs, sigma_gibbs] = bear.nwgibbs(It, Bu, ...
        betabar, phibar, Sbar, alphabar, alphatilde, n, k);
    [beta_median, ~, ~, ~, ~, sigma_median] = ...
        bear.nwestimates(betabar, phibar, Sbar, alphabar, alphatilde, n, k, cband);

elseif prior == 31 || prior == 32
    % Independent Normal-Wishart prior --------------------------------
    [beta0, omega0, S0, alpha0] = bear.inwprior(ar_vec, arvar, ...
        lambda1, lambda2, lambda3, lambda4_mat, lambda5, ...
        n, m, p, k, q, prior, bex, blockexo, priorexo);
    [beta_gibbs, sigma_gibbs] = bear.inwgibbs(It, Bu, ...
        beta0, omega0, S0, alpha0, Xstar, Ystar, ystar, Bhat, n, Tstar, q);
    [beta_median, ~, ~, ~, sigma_median] = ...
        bear.inwestimates(beta_gibbs, sigma_gibbs, cband, q, n, k);

elseif prior == 41
    % Normal-diffuse prior --------------------------------------------
    [beta0, omega0] = bear.ndprior(ar_vec, arvar, ...
        lambda1, lambda2, lambda3, lambda4_mat, lambda5, ...
        n, m, p, k, q, bex, blockexo, priorexo);
    if lambda1 > 999
        % Flat (diffuse) limit
        [beta_gibbs, sigma_gibbs] = bear.ndgibbstotal(It, Bu, ...
            Xstar, Ystar, ystar, Bhat, n, Tstar, q);
    else
        [beta_gibbs, sigma_gibbs] = bear.ndgibbs(It, Bu, ...
            beta0, omega0, Xstar, Ystar, ystar, Bhat, n, Tstar, q);
    end
    [beta_median, ~, ~, ~, sigma_median] = ...
        bear.ndestimates(beta_gibbs, sigma_gibbs, cband, q, n, k);

elseif prior == 51
    % Dummy-observation prior -----------------------------------------
    % doprior further augments Ystar/Xstar with dummy observations
    [Ystar, Xstar, Tstar] = bear.doprior(Ystar, Xstar, n, m, p, Tstar, ...
        ar_vec, arvar, lambda1, lambda3, lambda4_mat, priorexo);
    [Bcap, betacap, Scap, alphacap, phicap, alphatop] = ...
        bear.dopost(Xstar, Ystar, Tstar, k, n);
    [beta_gibbs, sigma_gibbs] = bear.dogibbs(It, Bu, ...
        Bcap, phicap, Scap, alphacap, alphatop, n, k);
    [beta_median, ~, ~, ~, ~, sigma_median] = ...
        bear.doestimates(betacap, phicap, Scap, alphacap, alphatop, n, k, cband);
end

%% -----------------------------------------------------------------------
%  Block 4: Structural identification – obtain D_record for HD
%  D_record is the n^2-by-(It-Bu) record of the structural matrix D at
%  each retained Gibbs iteration. Only D_record is needed by hdecomp.
%% -----------------------------------------------------------------------

if IRFt == 1
    % Unrestricted (D = identity at every iteration)
    [D_record, ~] = bear.irfunres(n, It, Bu, sigma_gibbs);

elseif IRFt == 2
    % Cholesky decomposition of sigma
    [irf_record] = bear.irf(beta_gibbs, It, Bu, IRFperiods, n, m, p, k);
    [~, D_record, ~, favar] = bear.irfchol(sigma_gibbs, irf_record, ...
        It, Bu, IRFperiods, n, favar);

elseif IRFt == 3
    % Triangular factorisation of sigma
    [irf_record] = bear.irf(beta_gibbs, It, Bu, IRFperiods, n, m, p, k);
    [~, D_record, ~, favar] = bear.irftrig(sigma_gibbs, irf_record, ...
        It, Bu, IRFperiods, n, favar);
end

%% -----------------------------------------------------------------------
%  Block 5: Historical decomposition
%% -----------------------------------------------------------------------

[hd_record, favar] = bear.hdecomp_inc_exo(beta_gibbs, D_record, ...
    It, Bu, Y, X, n, m, p, k, T, data_exo, exo, endo, const, ...
    IRFt, strctident, favar); %#ok<ASGLU>

[hd_estimates, ~] = bear.hdestimates_inc_exo(hd_record, n, T, HDband, favar);

%% -----------------------------------------------------------------------
%  Package results
%% -----------------------------------------------------------------------

results.hd_estimates = hd_estimates;
results.beta_median  = reshape(beta_median, k, n);
results.sigma_median = sigma_median;
results.n            = n;
results.m            = m;
results.p            = p;
results.T            = T;
results.k            = k;
results.endo_labels  = endo;
results.exo_labels   = exo;

end
