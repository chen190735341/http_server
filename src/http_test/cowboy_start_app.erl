%% Author: Administrator
%% Created: 2017-6-9
%% Description: TODO: Add description to cowboy_start_app
-module(cowboy_start_app).

-behaviour(application).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([
	 start/2,
	 stop/1
        ]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([start/0]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% API Functions
%% --------------------------------------------------------------------

start()->
	application:start(crypto),
	application:start(cowlib),
	application:start(ranch),
	application:start(cowboy),
	application:start(cowboy_start).

%% ====================================================================!
%% External functions
%% ====================================================================!
%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start(_Type, _StartArgs) ->
    case cowboy_start_sup:start_link() of
	{ok, _Pid} ->
		Port = list_to_integer(get_argument(port,"8007")),
		TcpAcceptors = list_to_integer(get_argument(tcpacceptors,"10")),
		BackLog = list_to_integer(get_argument(backlog,"1024")),
		cowboy_start_sup:start_cowboy_server(TcpAcceptors,Port,BackLog),
	    {ok, self()};
	Error ->
	    Error
    end.

%% --------------------------------------------------------------------
%% Func: stop/1
%% Returns: any
%% --------------------------------------------------------------------
stop(State) ->
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================
get_argument(Arg,Default)->
	case init:get_argument(Arg) of
		[[Arg]|_]->
			Arg;
		_->
			Default
	end.
		
