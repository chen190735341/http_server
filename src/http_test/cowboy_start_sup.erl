%%% -------------------------------------------------------------------
%%% Author  : Chen
%%% Description :
%%%
%%% Created : 2015-5-7
%%% -------------------------------------------------------------------
-module(cowboy_start_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/0,start_cowboy_server/3]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 init/1
        ]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(SERVER, ?MODULE).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_cowboy_server(TcpAcceptors,Port,BackLog)->
	%%修改backlog扩大socket监听队列(注意修改somaxconn,baclog受限于somaxconn),注意TcpAcceptors数量，要足够应付高并发
	TcpOpts = [{port,Port},{max_connections, infinity},{backlog,BackLog}], 
	Dispatch = cowboy_router:compile([
		{'_', [
			{'_', cowboy_test_handler, []}
		]}
	]),
	cowboy:start_http(cowboy_http_server, TcpAcceptors,TcpOpts, [{env, [{dispatch, Dispatch}]}]).


%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([]) ->
	{ok,{{one_for_all,0,1}, []}}.
%%     RanchChild = {'ranch_sup',{'ranch_sup',start_link,[]},
%% 	      permanent,2000,supervisor,['ranch_sup']},
%% 	CowboyChild = {'cowboy_sup',{'cowboy_sup',start_link,[]},
%% 	      permanent,2000,supervisor,['cowboy_sup']},
%%     {ok,{{one_for_all,0,1}, [RanchChild,CowboyChild]}}.

%% ====================================================================
%% Internal functions
%% ====================================================================

