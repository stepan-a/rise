function [db,states,retcode] = simulate(obj,varargin)

% simul_historical_data contains the historical data as well as information
%              over the forecast horizon. This also includes the future
%              path of the regimes, which is denoted by "regime" in the
%              database.
% simul_history_end_date controls the end of history

% the random numbers specifications and algorithms are specified outside
% this function. Need to check this again!!!
if isempty(obj)
    if nargout>1
        error([mfilename,':: when the object is emtpy, nargout must be at most 1'])
    end
    db=struct('simul_periods',100,...
        'simul_burn',100,...
        'simul_algo','mt19937ar',...  % [{mt19937ar}| mcg16807| mlfg6331_64|mrg32k3a|shr3cong|swb2712]
        'simul_seed',0,...
        'simul_historical_data',ts.empty(0),...
        'simul_history_end_date','',...
        'simul_start_date','',...
        'simul_regime',[]);
    return
end
nobj=numel(obj);
if nobj>1
    retcode=nan(1,nobj);
    states=cell(1,nobj);
    db=cell(1,nobj);
    for iobj=1:nobj
        [db{iobj},states{iobj},retcode(iobj)] = simulate(obj(iobj),varargin{:});
    end
    db=format_simulated_data_output(db);
    return
end

[obj,retcode]=solve(obj,varargin{:});
% note that the solving of the model may change the perturbation
% order. More explicitly optimal policy irfs will be computed for a
% perturbation of order 1 no matter what order the user chooses.
% This is because we have not solved the optimal policy problem
% beyond the first order.
if retcode
    error('model cannot be solved')
end

% initial conditions
%-------------------
Initcond=generic_tools.set_simulation_initial_conditions(obj);

ovSolution=load_order_var_solution(obj,Initcond.y);
y0=ovSolution.y0;
T=ovSolution.T;
steady_state=ovSolution.steady_state;

% here we need to start at one single point: and so we aggregate y0
%------------------------------------------------------------------
[y0]=utils.forecast.aggregate_initial_conditions(Initcond.PAI,y0);

[y,states,retcode]=utils.forecast.multi_step(y0(1),steady_state,T,Initcond);

% put y in the correct order before storing
%------------------------------------------
if isa(obj,'dsge')
    y=y(obj.inv_order_var.after_solve,:);
end

% store the simulations in a database: use the date for last observation in
% history and not first date of forecast
%--------------------------------------------------------------------------
y0cols=size(y0(1).y,2);
start_date=serial2date(date2serial(0)-y0cols+1);
db=ts(start_date,y',obj.endogenous.name);
db=pages2struct(db);

end

function sim_data=format_simulated_data_output(sim_data)
nobj=numel(sim_data);
if nobj==1
    sim_data=sim_data{1};
else
    if isempty(sim_data{1})
        return
    end
    sim_data=utils.time_series.concatenate_series_from_different_models(sim_data);
end
end