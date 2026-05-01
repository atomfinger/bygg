-module(bygg_test_runner_ffi).
-export([run_command/2, abs_path/1]).

run_command(Cmd, Dir) ->
    run_with_retry(Cmd, Dir, 5, 2000).

run_with_retry(Cmd, Dir, RetriesLeft, DelayMs) ->
    Result = run_once(Cmd, Dir),
    case Result of
        {ok, _} ->
            Result;
        {error, Output} when RetriesLeft > 0 ->
            case is_rate_limited(Output) of
                true ->
                    timer:sleep(DelayMs),
                    run_with_retry(Cmd, Dir, RetriesLeft - 1, DelayMs * 2);
                false ->
                    Result
            end;
        {error, _} ->
            Result
    end.

is_rate_limited(Output) ->
    Lower = string:lowercase(binary_to_list(Output)),
    string:find(Lower, "429") =/= nomatch orelse
    string:find(Lower, "rate limit") =/= nomatch orelse
    string:find(Lower, "too many requests") =/= nomatch.

run_once(Cmd, Dir) ->
    CmdStr = binary_to_list(Cmd),
    DirStr = binary_to_list(Dir),
    Port = open_port({spawn, CmdStr}, [
        exit_status,
        {cd, DirStr},
        stderr_to_stdout,
        {line, 4096}
    ]),
    collect(Port, []).

collect(Port, Acc) ->
    receive
        {Port, {data, {eol, Line}}} ->
            collect(Port, [list_to_binary(Line) | Acc]);
        {Port, {data, {noeol, Line}}} ->
            collect(Port, [list_to_binary(Line) | Acc]);
        {Port, {exit_status, 0}} ->
            Lines = lists:reverse(Acc),
            Output = iolist_to_binary(lists:join(<<"\n">>, Lines)),
            {ok, Output};
        {Port, {exit_status, _}} ->
            Lines = lists:reverse(Acc),
            Output = iolist_to_binary(lists:join(<<"\n">>, Lines)),
            {error, Output}
    end.

abs_path(Path) ->
    PathStr = binary_to_list(Path),
    list_to_binary(filename:absname(PathStr)).
