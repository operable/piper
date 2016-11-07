Terminals

interp_value text.

Nonterminals

interpexpr parts.

Rootsymbol interpexpr.

interpexpr ->
  parts : new_interpexpr('$1').

parts ->
  text : [?new_ast(string, [text_to_string('$1')])].
parts ->
  interp_value : [?parse_token('$1', var, fun(V) -> V end)].
parts ->
  text parts : [?new_ast(string, [text_to_string('$1')])] ++ '$2'.
parts ->
  interp_value parts : [?parse_token('$1', var, fun(V) -> V end)] ++ '$2'.

Erlang code.

-include("piper_cmd2_parser.hrl").

text_to_string({text, Position, Value}) ->
  {string, Position, Value}.

new_interpexpr(Values) ->
  case are_all_strings(Values) of
    true ->
      concatenate_strings(Values);
    false ->
      ?new_ast(interp_string, [Values])
  end.

are_all_strings([]) -> true;
are_all_strings([Str|T]) ->
  case is_string(Str) of
    true ->
      are_all_strings(T);
    false ->
      false
  end.

concatenate_strings([Str]) -> Str;
concatenate_strings([H|_]=Strings) ->
  Values = [maps:get('value', Str) || Str <- Strings],
  Updated = 'Elixir.Enum':join(Values),
  maps:put('value', Updated, H).

is_string(Str) when is_map(Str) ->
  case maps:get('__struct__', Str) of
    'Elixir.Piper.Command.Ast.String' ->
      true;
    _ ->
      false
  end;
is_string(_) -> false.

