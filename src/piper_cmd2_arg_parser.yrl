Terminals

%% Types
integer float bool short_option long_option text

%% Notation
equals.

Nonterminals

arg value.

Rootsymbol arg.

arg ->
  short_option equals value : ?new_ast(option, [[{name, option_name('$1')},
                                                {value, '$3'},
                                                {type, short}]]).
arg ->
  short_option equals : ?new_ast(option, [[{name, option_name('$1')},
                                           {value, next_arg},
                                           {type, short}]]).
arg ->
  short_option : ?new_ast(option, [[{name, option_name('$1')},
                                    {type, short}]]).
arg ->
  long_option equals value : ?new_ast(option, [[{name, option_name('$1')},
                                                {value, '$3'},
                                                {type, long}]]).
arg ->
  long_option equals : ?new_ast(option, [[{name, option_name('$1')},
                                          {value, next_arg},
                                          {type, long}]]).
arg ->
  long_option : ?new_ast(option, [[{name, option_name('$1')},
                                   {type, long}]]).
arg ->
  value : '$1'.

value ->
  integer : ?new_ast(integer, ['$1']).
value ->
  float : ?new_ast(float, ['$1']).
value ->
  bool : ?new_ast(bool, ['$1']).
value ->
  text : case piper_cmd2_var_lexer:possible_varexpr('$1') of
           true ->
             ?parse_token('$1', var, fun(V) -> V end);
           false ->
             ?new_ast(string, [text_to_string('$1')])
         end.

Erlang code.

-include("piper_cmd2_parser.hrl").

text_to_string({text, Position, Value}) ->
  {string, Position, Value}.

option_name({Type, {LineNum, Col}, Name}) when Type == long_option;
                                               Type == short_option ->
  Name1 = re:replace(Name, "^(\-\-|\-)", "", [{return, list}]),
  Col1 = Col + (length(Name) - length(Name1)),
  ?new_ast(string, [{string, {LineNum, Col1}, Name1}]).
