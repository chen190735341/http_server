%% Author: Chen
%% Created: 2015-5-8
%% Description: TODO: Add description to http_server_test_client
-module(http_server_test_client).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([
		 start_client_with_circle_in_time/7,
		 start_client_request/4
		]).

%%
%% API Functions
%%

%% count 一共多少波数 10
%% time 每波间隔时间 1000
%% num 每波多少个数 100
%% host 主机 "127.0.0.1"
%% port 端口 8007
%% bodysize 实体数据长度 10
%% LoopCount 没个tcp连接发送的http请求数量
%% http_server_test_client:start_client_with_circle_in_time(200,200,200,"192.168.1.49",8007,10,1).
start_client_with_circle_in_time(CircleCount,Time,Num,Host,Port,BodySize,LoopCount)->
	start_client_with_circle_in_time(CircleCount,CircleCount,Time,Num,Host,Port,BodySize,LoopCount).

start_client_with_circle_in_time(_MaxCircleCount,0,_Time,_Num,_Host,_Port,_BodySize,_LoopCount)->
	ok;
start_client_with_circle_in_time(MaxCircleCount,CircleCount,Time,Num,Host,Port,BodySize,LoopCount)->
	spawn(fun()->
				  timer:sleep((CircleCount-1)*Time),
				  start_client_with_count(MaxCircleCount,CircleCount,Num, Host, Port, BodySize, LoopCount)
		  end),
	start_client_with_circle_in_time(MaxCircleCount,CircleCount-1,Time,Num,Host,Port,BodySize,LoopCount).

start_client_with_count(MaxCircleCount,CircleCount,0,_Host,_Port,_BodySize,_LoopCount)->
	if
		CircleCount == MaxCircleCount->
			io:format("request send finish~n");
		true->
			nothing
	end,
	ok;
start_client_with_count(MaxCircleCount,CircleCount,Num,Host,Port,BodySize,LoopCount)->
	spawn(fun()->start_client_request(Host,Port,BodySize,LoopCount) end),
	start_client_with_count(MaxCircleCount,CircleCount,Num-1,Host,Port,BodySize,LoopCount).

%% host 主机 "127.0.0.1"
%% port 端口 8007
%% bodysize 实体数据长度 10
%% LoopCount 没个tcp连接发送的http请求数量
%% http_server_test_client:start_client_request("127.0.0.1",8007,10,1).

start_client_request(Host,Port,BodySize,LoopCount)->
	try
		Method = <<"post">>,
		Headers = [{<<"connection">>, <<"keepalive">>},{<<"content-type">>,<<"application/x-www-form-urlencoded">>}],
		Url = iolist_to_binary([<<"http://">>,list_to_binary(Host),<<":">>,list_to_binary(integer_to_list(Port)),<<"/gm_cmd?cmd=setclassicprogress&OpenId=60000000&PassValue=1&SubPassValue=20">>]),
		Body = list_to_binary(lists:duplicate(BodySize, $a)),
		{ok,Client} = cowboy_client:init([{reuseaddr,true}]),
		loop_request(LoopCount,Method,Headers,Url,Body,Client)
	catch
		Type:What ->
			Report = ["web request failed",
					  {type, Type}, {what, What},
					  {trace, erlang:get_stacktrace()}],
			error_logger:error_report(Report)
	end.

%%
loop_request(1,Method,Headers,Url,Body,Client)->
	case request_process(Method,Headers,Url,Body,Client) of
		{ok,TClient}->
			cowboy_client:close(TClient),
			ok;
		{error,_Reason}->
			error
	end;
loop_request(N,Method,Headers,Url,Body,Client)->
	case request_process(Method,Headers,Url,Body,Client) of
		{ok,NClient}->
			loop_request(N-1,Method,Headers,Url,Body,NClient);
		{error,_Reason}->
			error
	end.

request_process(Method,Headers,Url,Body,Client)->
	case catch cowboy_client:request(Method,Url,Headers,Body,Client) of
		{ok,Client2}->
			case catch cowboy_client:response(Client2) of
				{ok, 200, _Headers, Client3}->
					case catch cowboy_client:response_body(Client3) of
						{ok, _Body,Client4}->
							%% 					io:format("http_server_test_client request_process ,_Headers:~p,_Body:~p~n",[_Headers,_Body]),
							{ok,Client4};
						{error, Reason}->
							io:format("cowboy_client:response_body error  Reason:~p~n",[Reason]),
							{error,Reason}
					end;
				{ok, Status, _Headers, _Client3}->
					io:format("cowboy_client:response error Status:~p~n",[Status]),
					{error,Status};
				{error, Reason}->
					io:format(" cowboy_client:response error Reason:~p~n",[Reason]),
					{error,Reason}
			end;
		{error,Reason}->
			io:format("cowboy_client:request error Reason:~p~n",[Reason]),
			{error,Reason}
	end.
	
%%
%% Local Functions
%%

