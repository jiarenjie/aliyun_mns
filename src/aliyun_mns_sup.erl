%%%-------------------------------------------------------------------
%% @doc aliyun_sms top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(aliyun_mns_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
%%    {ok, { {one_for_all, 0, 1}, []} }.
    RestartStrategy = {one_for_one, 4, 60},
    Children = [
        {gs_aliyun_mns,
        {gs_aliyun_mns, start_link, []},
        permanent, 2000, supervisor, [gs_aliyun_mns]},
        {gs_aliyun_sms,
            {gs_aliyun_sms, start_link, []},
            permanent, 2000, supervisor, [gs_aliyun_sms]}
    ],
    {ok, {RestartStrategy, Children}}.



%%====================================================================
%% Internal functions
%%====================================================================
