%% Author: Chen
%% Created: 2015-5-8
%% Description: TODO: Add description to cowboy_http_test_server
-module(cowboy_http_test_server).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/3]).

%%
%% API Functions
%%

%% 启动cowboy http server
%% TcpAcceptors tcp acceptor个数
%% port 端口
%% cowboy_http_test_server:start(16,8007,1024).

start(TcpAcceptors,Port,BackLog)->
	ranch_sup:start_link(),
	cowboy_sup:start_link(),
	Opt = [{port,Port},{max_connections, infinity},{backlog,BackLog}],
	Dispatch = cowboy_router:compile([
		{'_', [
			{'_', cowboy_test_handler, []}
		]}
	]),
	cowboy:start_http(cowboy_http_test_server, TcpAcceptors,Opt, [{env, [{dispatch, Dispatch}]}],2).



%%
%% Local Functions
%%

