Terminals

%% Types
variable integer text

%% Notation
lbracket rbracket dot.

Nonterminals

varexpr varops.

Rootsymbol varexpr.

varexpr ->
  variable : make_variable('$1').
varexpr ->
  variable varops : make_variable('$1', '$2').

varops ->
  lbracket integer rbracket : [{index, index_value('$2')}].
varops ->
  lbracket variable rbracket : [{index, make_variable('$2')}].
varops ->
  lbracket variable varops rbracket : [{index, make_variable('$2', '$3')}].
varops ->
  lbracket text rbracket : [{key, key_value('$2')}].
varops ->
  lbracket integer rbracket varops : [{index, index_value('$2')}] ++ '$4'.
varops ->
  lbracket variable rbracket varops : [{index, make_variable('$2')}] ++ '$4'.
varops ->
  lbracket variable varops rbracket varops : [{index, make_variable('$2', '$3')}] ++ '$5'.
varops ->
  lbracket text rbracket varops : [{key, key_value('$2')}] ++ '$4'.
varops ->
  dot text : [{key, key_value('$2')}].
varops ->
  dot text varops : [{key, key_value('$2')}] ++ '$3'.

Erlang code.

-include("piper_cmd2_parser.hrl").

index_value({integer, _, Value}) ->
  list_to_integer(Value).

key_value({text, _, [$'|_]=Value}) ->
  re:replace(Value, "^'|'$", "", [{return, binary}, global]);
key_value({text, _, [$"|_]=Value}) ->
  re:replace(Value, "^\"|\"$", "", [{return, binary}, global]);
key_value({text, _, Value}) ->
  list_to_binary(Value).

make_variable(Var) ->
  make_variable(Var, []).

make_variable({variable, Position, Name}, Ops) ->
  Var1 = {variable, Position, re:replace(Name, "^\\$", "", [{return, list}, global])},
  ?new_ast(variable, [Var1, Ops]).
