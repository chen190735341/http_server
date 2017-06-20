%% Author: adrianx-win7
%% Created: 2011-11-30
%% Description: TODO: Add description to os_util
-module(os_util).
%%
%% Include files
%%
-define(COOKIE,"abc").
%%
%% Exported Functions
%%
-compile(export_all).
-export([get_localips/0]).

%%
%% API Functions
%%


run_erl(RunOption,FormatArgs)->
	Name = 
		case lists:keyfind(name, 1, FormatArgs) of
			{name,[TName|_]}->
				TName;
			_->
				"cowboy_node"
		end,
	SmpEnable = 
		case lists:keyfind(smp, 1, FormatArgs) of
			{smp,["true"|_]}->
				true;
			{smp,["false"|_]}->
				false;
			_->
				false
		end,
	Hiden = 
		case lists:keyfind(hiden, 1, FormatArgs) of
			{hiden,["true"|_]}->
				true;
			{hiden,["false"|_]}->
				false;
			_->
				false
		end,
	Wait = 
		case lists:keyfind(wait, 1, FormatArgs) of
			{wait,["true"|_]}->
				true;
			{wait,["false"|_]}->
				false;
			_->
				true
		end,
	MnesiaDir = 
		case lists:keyfind(mnesia_dir, 1, FormatArgs) of
			{mnesia_dir,[TMnesiaDir|_]}->
				TMnesiaDir;
			_->
				""
		end,
	Host = 
		case lists:keyfind(host, 1, FormatArgs) of
			{host,[THost|_]}->
				THost;
			_->
				get_localip()
		end,
	io:format("Hiden:~p,Name:~p, MnesiaDir:~p, SmpEnable:~p, Wait:~p, RunOption:~p,Host:~p~n",
			  [Hiden,Name, MnesiaDir, SmpEnable, Wait, RunOption,Host]),
	run_erl(Hiden,Name, MnesiaDir, SmpEnable, Wait, RunOption,Host).

run_erl(Hiden,Name,MnesiaDir,SmpEnable,Wait,Option,Host)->
	CommandLine = get_erl_cmd(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option),
	io:format("CommandLine:~p~n",[CommandLine]),
	if
		Wait->
			wait_exe(CommandLine);
		true->
			run_exe(CommandLine)
	end.

run_shell_exe(CmdLine)->
	erl_command:main(CmdLine).

%%异步执行，不等执行完成
run_exe(CmdLine)->
	cmd_ansync(CmdLine).

%% 同步执行，等执行完成
wait_exe(CmdLine)->
	io:format("~s~n",[CmdLine]),
	os:cmd(CmdLine).

stop_node([Node])->
	io:format("nodes():~p~n",[net_adm:ping(Node)]),
	rpc:call(Node, ?MODULE, stop, []),
	io:format("stopping the node ~p ~n",[Node]),
	os_wait(1),
	Node.

os_wait(N) when is_integer(N)->
	CmdLine =  case os:type() of
				   {win32,nt}->
					    sprintf("ping 127.0.0.1 -n ~p", [N]);
				   _-> lists:flatten("sleep ~p", [N])
			   end,
	os:cmd(CmdLine);
os_wait(_)->
	io:format("error wait input").

stop()->
	init:stop(),
	ok.

get_erl_cmd(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,TOption)->
	Option = " -cookie "++?COOKIE++" "++TOption,
	HidenOption =
		if
			Hiden->
				" -noshell -noinput ";
			true->
				""
		end,
	NameOption = case Name of
					 []-> "";
					 _ -> sprintf(" -name ~s@~s ",[Name,Host])
				 end,
	DBOption = case MnesiaDir of
					 []-> "";
				 	 _ -> sprintf(" -mnesia dir '\"~s\"' ", [MnesiaDir])
				 end,
	
	SMPOption  = 
		if
			SmpEnable->
				"";
			true->
				case os:type() of
					{win32,nt}-> " ";
					_-> " -smp disable "
				end
		end,
	ExeCmd = case os:type() of 
				 {win32,nt}->
					 "start cmd.exe /k erl.exe +t 20000000 +P 500000 ";
				 _->
					 "erl +t 20000000 +P 500000 +K true "
			 end,
	lists:append([ExeCmd, HidenOption ,NameOption,DBOption , SMPOption , Option]).	

%% Executes the given command in the default shell for the operating system.
-spec cmd_ansync(Command) -> atom() when
      Command :: atom() | io_lib:chars().
cmd_ansync(Cmd) ->
	cmd_ansync(Cmd, infinity).

-spec cmd_ansync(Command,TimeOut) -> atom() when
      Command :: atom() | io_lib:chars(),
	  TimeOut :: integer()|infinit.

cmd_ansync(Cmd,TimeOut) ->
	CurPid = self(),
	Fun = fun()->do_cmd_ansync(Cmd,CurPid) end,
	proc_lib:spawn(Fun),
	receive 
		ok-> 
			io:format("Command OK ~s~n",[Cmd]),
			ok;
		Error->
			io:format("Command Error:~p ~s~n",[Error,Cmd]),
			error
	end.

do_cmd_ansync(Cmd,MonitorPid) ->
    validate(Cmd),
    case os:type() of
	{unix, _} ->
	    unix_cmd(Cmd,MonitorPid);
	{win32, Wtype} ->
	    Command = case {os:getenv("COMSPEC"),Wtype} of
			  {false,windows} -> lists:concat(["command.com /c", Cmd]);
			  {false,_} -> lists:concat(["cmd /c", Cmd]);
			  {Cspec,_} -> lists:concat([Cspec," /c",Cmd])
		      end,
	    Port = open_port({spawn, Command}, [stream, in, eof, hide]),
		MonitorPid ! ok,
	    get_data(Port, []);
	%% VxWorks uses a 'sh -c hook' in 'vxcall.c' to run os:cmd.
	vxworks ->
	    Command = lists:concat(["sh -c '", Cmd, "'"]),
	    Port = open_port({spawn, Command}, [stream, in, eof]),
		MonitorPid ! ok,
	    get_data(Port, [])
    end.

unix_cmd(Cmd,MonitorPid) ->
    Tag = make_ref(),
    {Pid,Mref} = erlang:spawn_monitor(
		   fun() ->
			   process_flag(trap_exit, true),
			   Port = start_port(),
			   erlang:port_command(Port, mk_cmd(Cmd)),
			   MonitorPid ! ok,
			   exit({Tag,unix_get_data(Port)})
		   end),
    receive
	{'DOWN',Mref,_,Pid,{Tag,Result}} ->
	    Result;
	{'DOWN',Mref,_,Pid,Reason} ->
	    exit(Reason)
    end.



%% The -s flag implies that only the positional parameters are set,
%% and the commands are read from standard input. We set the 
%% $1 parameter for easy identification of the resident shell.
%%
-define(SHELL, "/bin/sh -s unix:cmd 2>&1").
-define(PORT_CREATOR_NAME, os_cmd_port_creator).

%%
%% Serializing open_port through a process to avoid smp lock contention
%% when many concurrent os:cmd() want to do vfork (OTP-7890).
%%
-spec start_port() -> port().
start_port() ->
    Ref = make_ref(),
    Request = {Ref,self()},    
    {Pid, Mon} = case whereis(?PORT_CREATOR_NAME) of
		     undefined ->
			 spawn_monitor(fun() ->
					       start_port_srv(Request)
				       end);
		     P ->
			 P ! Request,
			 M = erlang:monitor(process, P),
			 {P, M}
		 end,
    receive
	{Ref, Port} when is_port(Port) ->
	    erlang:demonitor(Mon, [flush]),
	    Port;
	{Ref, Error} ->
	    erlang:demonitor(Mon, [flush]),
	    exit(Error);
	{'DOWN', Mon, process, Pid, _Reason} ->
	    start_port()
    end.


start_port_srv(Request) ->
    %% We don't want a group leader of some random application. Use
    %% kernel_sup's group leader.
    {group_leader, GL} = process_info(whereis(kernel_sup),
				      group_leader),
    true = group_leader(GL, self()),
    process_flag(trap_exit, true),
    StayAlive = try register(?PORT_CREATOR_NAME, self())
		catch
		    error:_ -> false
		end,
    start_port_srv_handle(Request),
    case StayAlive of
	true -> start_port_srv_loop();
	false -> exiting
    end.

start_port_srv_handle({Ref,Client}) ->
    Reply = try open_port({spawn, ?SHELL},[stream]) of
		Port when is_port(Port) ->
		    (catch port_connect(Port, Client)),
		    unlink(Port),
		    Port
	    catch
		error:Reason ->
		    {Reason,erlang:get_stacktrace()}	    
	    end,
    Client ! {Ref,Reply}.


start_port_srv_loop() ->
    receive
	{Ref, Client} = Request when is_reference(Ref),
				     is_pid(Client) ->
	    start_port_srv_handle(Request);
	_Junk ->
	    ignore
    end,
    start_port_srv_loop().


%%
%%  unix_get_data(Port) -> Result
%%
unix_get_data(Port) ->
    unix_get_data(Port, []).

unix_get_data(Port, Sofar) ->
    receive
	{Port,{data, Bytes}} ->
	    case eot(Bytes) of
		{done, Last} ->
		    lists:flatten([Sofar|Last]);
		more  ->
		    unix_get_data(Port, [Sofar|Bytes])
	    end;
	{'EXIT', Port, _} ->
	    lists:flatten(Sofar)
    end.



%%
%% eot(String) -> more | {done, Result}
%%
eot(Bs) ->
    eot(Bs, []).

eot([4| _Bs], As) ->
    {done, lists:reverse(As)};
eot([B| Bs], As) ->
    eot(Bs, [B| As]);
eot([], _As) ->
    more.

%%
%% mk_cmd(Cmd) -> {ok, ShellCommandString} | {error, ErrorString}
%%
%% We do not allow any input to Cmd (hence commands that want
%% to read from standard input will return immediately).
%% Standard error is redirected to standard output.
%%
%% We use ^D (= EOT = 4) to mark the end of the stream.
%%
mk_cmd(Cmd) when is_atom(Cmd) ->		% backward comp.
    mk_cmd(atom_to_list(Cmd));
mk_cmd(Cmd) ->
    %% We insert a new line after the command, in case the command
    %% contains a comment character.
    io_lib:format("(~s\n) </dev/null; echo  \"\^D\"\n", [Cmd]).

validate(Atom) when is_atom(Atom) ->
    ok;
validate(List) when is_list(List) ->
    validate1(List).

validate1([C|Rest]) when is_integer(C), 0 =< C, C < 256 ->
    validate1(Rest);
validate1([List|Rest]) when is_list(List) ->
    validate1(List),
    validate1(Rest);
validate1([]) ->
    ok.

get_data(Port, Sofar) ->
    receive
	{Port, {data, Bytes}} ->
	    get_data(Port, [Sofar|Bytes]);
	{Port, eof} ->
	    Port ! {self(), close}, 
	    receive
		{Port, closed} ->
		    true
	    end, 
	    receive
		{'EXIT',  Port,  _} -> 
		    ok
	    after 1 ->				% force context switch
		    ok
	    end, 
	    lists:flatten(Sofar)
    end.



get_localips()->
	case inet:getif() of
		{ok,IFs}->
			SortedIFs = lists:sort(fun(IP1,IP2)-> 
										   {{I1,I2,I3,I4},_,_} = IP1,
										   {{J1,J2,J3,J4},_,_} = IP2,
										   if I1 =:= 192 -> true;
											  J1 =:= 192 -> false;
											  I1 =:= 127 -> true;
											  J1 =:= 127 -> false;
											  I1 < J1 -> true;
											  I1 > J1 -> false;
											  I2 < J2 -> true;
											  I2 > J2 -> false;
											  I3 < J3 -> true;
											  I3 > J3 -> false;
											  I4 < J4 -> true;
											  I4 > J4 -> false;
											  true-> false
										   end
								   end, IFs),
			lists:map(fun(IfConfig)->
							case IfConfig of
								{{192,168,I3,I4},_,_}-> "192.168." ++ integer_to_list(I3) ++"." ++ integer_to_list(I4);
								{{127,0,0,I4},_,_}->"127.0.0." ++ integer_to_list(I4);
								{{10,I2,I3,I4},_,_}->sprintf("10.~p.~p.~p", [I2,I3,I4]);
								{{I1,I2,I3,I4},_,_}->sprintf("~p.~p.~p.~p", [I1,I2,I3,I4])
							end
					end,SortedIFs);
		_->[]
	end.
get_localip()->
	case get_localips() of
		[]->[];
		[IP|_]-> IP
	end.

%% 解析参数
analysis_argments(Args)->
	analysis_argments(Args,[]).

analysis_argments([],FormatArgs)->
	lists:reverse(FormatArgs);
analysis_argments([Arg|Args],FormatArgs)->
	case check_if_flag(Arg) of
		{true,Flag}->
			{LeftArgs,Arguments} = get_flag_arguments(Args,[]),
			analysis_argments(LeftArgs,[{Flag,Arguments}|FormatArgs]);
		false->
			error
	end.
			

check_if_flag([$-|Flag])->
	{true,erlang:list_to_atom(Flag)};
check_if_flag(_)->
	false.

get_flag_arguments([],FlagArguments)->
	{[],lists:reverse(FlagArguments)};
get_flag_arguments([Arg|LeftArgs],FlagArguments)->
	case check_if_flag(Arg) of
		{true,_}->
			{[Arg|LeftArgs],lists:reverse(FlagArguments)};
		false->
			get_flag_arguments(LeftArgs,[Arg|FlagArguments])
	end.
		
print_args(Args,FormatArgs)->
	io:format("original args:~p~n",[Args]),
	io:format("format args:~p~n",[FormatArgs]).
	
get_arg(Flag,FormatArgs,Type,Default)->
	case lists:keyfind(Flag,1,FormatArgs) of
		{Flag,Arguments}->
			trans_type(Arguments,Type,Default);
		false->
			{true,Default}
	end.

trans_type(_,flag,_Default)->
	{true,[]};
trans_type([],_Type,_Default)->
	{true,[]};
trans_type(Arguments,Type,Default)->
	if
		Type == int->
			[Arg|_] = Arguments,
			case is_integer(Arg) of
				true->
					list_to_integer(Arg);
				false->
					Default
			end;
		true->
			Arguments
	end.

sprintf(Format,Data)->
	lists:flatten(io_lib:format(Format, Data)).
