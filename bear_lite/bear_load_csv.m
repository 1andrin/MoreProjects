function [data, varnames] = bear_load_csv(filepath)
% BEAR_LOAD_CSV  Load a CSV file into the numeric matrix expected by bear_run.
%
%   [DATA, VARNAMES] = BEAR_LOAD_CSV(FILEPATH)
%
%   The CSV must have a header row with variable names. The first column
%   may optionally be a non-numeric date/index column (e.g. '2000Q1');
%   it is detected automatically and skipped.
%
%   DATA     - T-by-n double matrix (rows = observations, columns = variables)
%   VARNAMES - 1-by-n cell array of variable name strings
%
%   Example (Python side):
%     df.to_csv('data.csv', index=False)          % columns = variable names
%   or with a date index:
%     df.to_csv('data.csv', index=True)           % first column = dates (skipped)
%
%   Example (MATLAB side):
%     [endo, endo_names] = bear_load_csv('path/to/endo.csv');
%     [exo,  exo_names]  = bear_load_csv('path/to/exo.csv');
%     s       = bear_settings();
%     results = bear_run(s, endo, exo);

T = readtable(filepath, 'VariableNamingRule', 'preserve');

% Identify numeric columns (non-numeric first column = date index, skip it)
is_numeric = varfun(@(c) isnumeric(c), T, 'OutputFormat', 'uniform');

data     = T{:, is_numeric};
varnames = T.Properties.VariableNames(is_numeric);
end
