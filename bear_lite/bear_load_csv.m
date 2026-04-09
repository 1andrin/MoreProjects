function [data, varnames, dates] = bear_load_csv(filepath)
% BEAR_LOAD_CSV  Load a CSV file into the numeric matrix expected by bear_run.
%
%   [DATA, VARNAMES] = BEAR_LOAD_CSV(FILEPATH)
%   [DATA, VARNAMES, DATES] = BEAR_LOAD_CSV(FILEPATH)
%
%   The CSV must have a header row with variable names. The first column
%   may optionally be a non-numeric date/index column (e.g. '2000Q1');
%   it is detected automatically and skipped from DATA.
%
%   DATA     - T-by-n double matrix (rows = observations, columns = variables)
%   VARNAMES - 1-by-n cell array of variable name strings
%   DATES    - T-by-1 string array of date labels (first non-numeric column),
%              or string integers '1','2',... if no date column is present
%
%   Example (Python side):
%     df.to_csv('data.csv', index=False)          % columns = variable names
%   or with a date index:
%     df.to_csv('data.csv', index=True)           % first column = dates
%
%   Example (MATLAB side):
%     [endo, names, dates] = bear_load_csv('path/to/endo.csv');
%     s       = bear_settings();
%     results = bear_run(s, endo);

T = readtable(filepath, 'VariableNamingRule', 'preserve');

% Identify numeric columns (non-numeric first column = date index, skip it)
is_numeric = varfun(@(c) isnumeric(c), T, 'OutputFormat', 'uniform');

data     = T{:, is_numeric};
varnames = T.Properties.VariableNames(is_numeric);

if nargout >= 3
    non_numeric = T.Properties.VariableNames(~is_numeric);
    if ~isempty(non_numeric)
        col = T.(non_numeric{1});
        if isdatetime(col)
            dates = string(col, 'yyyy-MM-dd');
        else
            dates = string(col);
        end
    else
        dates = string((1:size(data,1))');
    end
end
end
