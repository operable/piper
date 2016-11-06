Terminals

interp_value text.

Nonterminals

interpexpr parts.

Rootsymbol interpexpr.

interpexpr ->
  parts : ?new_ast(interp_string, ['$1']).

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
  {string, Position, list_to_binary(Value)}.
