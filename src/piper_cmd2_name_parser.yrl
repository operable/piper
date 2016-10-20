Terminals

name emoji colon.

Nonterminals

call qualified_call unqualified_call.

Rootsymbol call.

call ->
  qualified_call : '$1'.
call ->
  unqualified_call : '$1'.

qualified_call ->
  name colon name : ?new_ast(name, [[{bundle, name_to_string('$1')},
                                     {entity, name_to_string('$3')}]]).
qualified_call ->
  name colon emoji : ?new_ast(name, [[{bundle, name_to_string('$1')},
                                      {entity, name_to_string('$3')}]]).

unqualified_call ->
  name : ?new_ast(name, [[{entity, name_to_string('$1')}]]).
unqualified_call ->
  emoji : ?new_ast(name, [[{entity, '$1'}]]).

Erlang code.

-include("piper_cmd2_parser.hrl").

name_to_string({name, Position, Value}) ->
  {string, Position, Value};
name_to_string({emoji, Position, Value}) ->
  {string, Position, Value}.

