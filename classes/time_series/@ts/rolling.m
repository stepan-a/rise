function db=rolling(db,func,window,varargin)%,min_periods
% H1 line
%
% Syntax
% -------
% ::
%
% Inputs
% -------
%
% Outputs
% --------
%
% More About
% ------------
%
% Examples
% ---------
%
% See also: 


db=ts_roll_or_expand(db,func,window,varargin{:});

end