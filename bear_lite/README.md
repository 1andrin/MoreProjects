# bear_lite

A standalone, minimal wrapper around the BEAR toolbox for running a standard
Bayesian VAR (BVAR) and computing the **historical decomposition (HD)**.

This folder is fully self-contained and does **not** depend on any other file
in the BEAR toolbox repository.

---

## Files

```
bear_lite/
  bear_settings.m      – Settings constructor (returns a struct with defaults)
  bear_run.m           – Main entry point
  +bear/               – Internal package (copied verbatim from the BEAR toolbox)
    36 algorithm and utility files
```

### What was removed

Everything not needed for standard BVAR + historical decomposition:

| Removed                            | Reason                                    |
|------------------------------------|-------------------------------------------|
| OLS VAR, Panel BVAR, SV, TVP, MF  | Only standard BVAR (VARtype=2) is needed  |
| FAVAR                              | Not needed                                |
| Forecasts / conditional forecasts  | Not needed                                |
| FEVD                               | Not needed                                |
| Sign/IV restrictions (IRFt 4,5,6) | Not needed; Cholesky/triangular suffice   |
| Mean-adjusted BVAR (prior=61)      | Complex; omitted                          |
| All display/plotting functions     | Replaced by returning a struct            |
| Excel I/O (xlsread/xlswrite)       | Replaced by direct matrix input           |
| Grid search (hogs)                 | Not needed                                |
| Block exogeneity tables            | Supported via settings.bex=0 default     |
| `gensample`, `gendates`            | Replaced by direct data matrix input      |

---

## Setup

Add **only** `bear_lite` to your MATLAB path (do **not** add `tbx/bear`
alongside it to avoid namespace conflicts with the `+bear` package):

```matlab
addpath('/path/to/tbx/bear_lite')
```

---

## Quick start

```matlab
addpath('/path/to/tbx/bear_lite')

% --- Data ---
% Load your T-by-n data matrix (rows = time, columns = variables)
data = randn(120, 3);   % example: 120 observations, 3 variables

% --- Settings ---
s = bear_settings();    % start from defaults
s.prior = 11;           % Minnesota prior (see bear_settings.m for all options)
s.IRFt  = 2;            % Cholesky identification
s.lags  = 4;            % 4 lags
s.It    = 2000;         % Gibbs iterations
s.Bu    = 1000;         % burn-in

% --- Run ---
results = bear_run(s, data);

% --- Inspect HD ---
% hd_estimates is a (C+2)-by-n cell array.
% C = n_shocks(n) + initial_conditions(1) + constant(1) [+ exo if provided]
% Each cell is [lower; median; upper] (3 x T).

n = results.n;  % number of variables = 3

% Median contribution of shock 1 to variable 1 over the sample:
contrib_shock1_var1 = results.hd_estimates{1, 1}(2, :);   % row 2 = median

% Median contribution of the constant to variable 1:
contrib_const_var1  = results.hd_estimates{n+2, 1}(2, :);
```

### With exogenous variables

```matlab
data_endo = randn(120, 3);
data_exo  = randn(120, 2);   % 2 exogenous variables
results = bear_run(s, data_endo, data_exo);
% exogenous contribution is in hd_estimates{n+3, i}
```

---

## HD cell array layout

| Row index  | Content                                        |
|------------|------------------------------------------------|
| `1 .. n`   | Contribution of structural shock `j` to var `i`|
| `n+1`      | Initial conditions                             |
| `n+2`      | Constant (when `settings.const = 1`)           |
| `n+3`      | Exogenous variables (when `data_exo` supplied) |
| `C+1`      | Unexplained part (always zero for IRFt 1-3)   |
| `C+2`      | Portion explained by structural shocks         |

Each cell contains a **3-by-T** matrix: `[lower_bound; median; upper_bound]`.
Band width is controlled by `settings.HDband` (default 0.68).

---

## Supported settings

| Setting    | Default | Description                                       |
|------------|---------|---------------------------------------------------|
| `prior`    | `11`    | 11–13=Minnesota, 21–22=Normal-Wishart, 31–32=Independent NW, 41=Normal-diffuse, 51=Dummy obs |
| `IRFt`     | `2`     | 1=Unrestricted, 2=Cholesky, 3=Triangular          |
| `IRFperiods`| `20`   | IRF horizon (affects computation but not HD)       |
| `It`       | `2000`  | Total Gibbs iterations                            |
| `Bu`       | `1000`  | Burn-in iterations                                |
| `lags`     | `4`     | Number of VAR lags                                |
| `const`    | `1`     | Include constant (1=yes, 0=no)                    |
| `ar`       | `0.8`   | AR prior coefficient (scalar or n-by-1 vector)    |
| `lambda1`  | `0.1`   | Overall prior tightness                           |
| `lambda2`  | `0.5`   | Cross-variable weighting                          |
| `lambda3`  | `1`     | Lag decay                                         |
| `lambda4`  | `100`   | Exogenous/constant prior tightness                |
| `lambda5`  | `0.001` | Block exogeneity shrinkage                        |
| `lambda6`  | `0.1`   | Sum-of-coefficients tightness (only if `scoeff=1`)|
| `lambda7`  | `0.001` | Initial observation tightness (only if `iobs=1`)  |
| `lambda8`  | `1`     | Long-run prior tightness (only if `lrp=1`)        |
| `bex`      | `0`     | Block exogeneity (0=no)                           |
| `scoeff`   | `0`     | Sum-of-coefficients dummy (0=no)                  |
| `iobs`     | `0`     | Initial observation dummy (0=no)                  |
| `lrp`      | `0`     | Long-run prior (0=no)                             |
| `HDband`   | `0.68`  | Confidence band for HD                            |
| `cband`    | `0.68`  | Confidence band for coefficient estimates         |

---

## Equivalence with the full BEAR toolbox

The algorithm files in `+bear/` are **exact copies** of the originals. No
core estimation code has been modified. Results obtained with `bear_run` are
numerically identical to those produced by `BEARmain` with the same settings
and data (given the same random seed).
