-module(piper_cmd2_lexer_util).

-export([dummy_context/0,
         position/0,
         advance_line/1,
         advance_count/1]).

dummy_context() ->
  {ok, Pid} = 'Elixir.Piper.Command.ParseContext':start_link(2),
  erlang:put(piper_cp_context, Pid).

position() ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':position(Context).

advance_line(TokenLine) ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':start_line(Context, TokenLine).

advance_count(Count) ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':advance_count(Context, Count).

