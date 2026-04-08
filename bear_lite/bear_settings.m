function s = bear_settings()
% BEAR_SETTINGS  Return a settings struct with default values for bear_run.
%
%   S = BEAR_SETTINGS() returns a struct with all fields set to their
%   defaults. Modify fields before passing to bear_run.
%
%   Fields:
%     prior      - Prior type (default 11)
%                    11 = Minnesota (univariate AR sigma)
%                    12 = Minnesota (diagonal VAR sigma)
%                    13 = Minnesota (full VAR sigma)
%                    21 = Normal-Wishart (S0 as univariate AR)
%                    22 = Normal-Wishart (S0 as identity)
%                    31 = Independent Normal-Wishart (S0 as univariate AR)
%                    32 = Independent Normal-Wishart (S0 as identity)
%                    41 = Normal-diffuse
%                    51 = Dummy observations
%     IRFt       - Structural identification (default 2)
%                    1 = Unrestricted (reduced form)
%                    2 = Cholesky decomposition
%                    3 = Triangular factorisation
%     IRFperiods - Periods for IRF computation (default 20)
%     It         - Total Gibbs sampler iterations (default 2000)
%     Bu         - Burn-in iterations (default 1000)
%     lags       - Number of VAR lags (default 4)
%     const      - Include constant (1=yes, 0=no; default 1)
%     ar         - AR coefficient prior (scalar or n-by-1; default 0.8)
%     lambda1    - Overall tightness (default 0.1)
%     lambda2    - Cross-variable weighting (default 0.5)
%     lambda3    - Lag decay (default 1)
%     lambda4    - Exogenous/constant tightness (default 100)
%     lambda5    - Block exogeneity shrinkage (default 0.001)
%     lambda6    - Sum-of-coefficients tightness (default 0.1, only when scoeff=1)
%     lambda7    - Dummy initial observation tightness (default 0.001, only when iobs=1)
%     lambda8    - Long-run prior tightness (default 1, only when lrp=1)
%     bex        - Block exogeneity (0=no, 1=yes; default 0)
%     scoeff     - Sum-of-coefficients dummy prior (0=no, 1=yes; default 0)
%     iobs       - Initial observation dummy prior (0=no, 1=yes; default 0)
%     lrp        - Long-run prior (0=no, 1=yes; default 0)
%     HDband     - Confidence band for HD (default 0.68)
%     cband      - Confidence band for VAR coefficients (default 0.68)
%
%   Example:
%     s = bear_settings();
%     s.prior = 21;    % Normal-Wishart prior
%     s.lags  = 2;     % 2 lags
%     s.It    = 5000;  % more Gibbs iterations
%     data = randn(100, 3);
%     results = bear_run(s, data);

s.prior      = 11;
s.IRFt       = 2;
s.IRFperiods = 20;
s.It         = 2000;
s.Bu         = 1000;
s.lags       = 4;
s.const      = 1;
s.ar         = 0.8;
s.lambda1    = 0.1;
s.lambda2    = 0.5;
s.lambda3    = 1;
s.lambda4    = 100;
s.lambda5    = 0.001;
s.lambda6    = 0.1;
s.lambda7    = 0.001;
s.lambda8    = 1;
s.bex        = 0;
s.scoeff     = 0;
s.iobs       = 0;
s.lrp        = 0;
s.HDband     = 0.68;
s.cband      = 0.68;
end
