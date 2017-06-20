%% Author: Chen
%% Created: 2015-5-6
%% Description: TODO: Add description to cowboy_test_handler
-module(cowboy_test_handler).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-behaviour(cowboy_http_handler).
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

%%
%% API Functions
%%

init(_Type, Req, _Opts) ->
	{ok, Req, []}.

handle(Req, State) ->
	{_QsVals,Req1} = cowboy_req:qs_vals(Req),
	{ok, Body, Req2} = cowboy_req:body(infinity,Req1),
	{ok, Req3} = cowboy_req:reply(200, [
		{<<"content-type">>, <<"text/plain">>}
	], Body, Req2),
	{ok, Req3, State}.

terminate(_Reason, _Req, _State) ->
	ok.

%%
%% Local Functions
%%

