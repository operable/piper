Terminals

% Datatypes
opt_name float integer string property_name variable

% Notation
equals lbracket rbracket.

Nonterminals

args arg var_expr var_ops var_op.

Rootsymbol args.

Expect 1.

args ->
  arg args : ['$1'] ++ '$2'.
args ->
  arg : ['$1'].

arg ->
  string : ?AST("String"):new('$1').
arg ->
  property_name : '$1'.
arg ->
  var_expr : '$1'.
arg ->
  opt_name : ?AST("Option"):new([{name, value('$1')}]).
arg ->
  opt_name equals : ?AST("Option"):new([{name, value('$1')},
                                        {needs_value, true}]).
arg ->
  opt_name equals float : ?AST("Option"):new([{name, value('$1')},
                                              {value, ?AST("Float"):new('$3')}]).
arg ->
  opt_name equals integer : ?AST("Option"):new([{name, value('$1')},
                                                {value, ?AST("Integer"):new('$3')}]).
arg ->
  opt_name equals string : ?AST("Option"):new([{name, value('$1')},
                                               {value, ?AST("String"):new('$3')}]).
arg ->
  opt_name equals var_expr : ?AST("Option"):new([{name, value('$1')},
                                                 {value, '$3'}]).
var_expr ->
  variable : ?AST("Variable"):new('$1').
var_expr ->
  variable var_ops : ?AST("Variable"):new('$1', '$2').

var_ops ->
  var_op var_ops : '$1' ++ '$2'.
var_ops ->
  var_op: '$1'.

var_op ->
  lbracket integer rbracket : [{index, token_to_integer('$2')}].
var_op ->
  lbracket string rbracket : [{key, token_to_string('$2')}].
var_ops ->
  property_name : [_|PropName] = extract('$1'), [{key, list_to_binary(PropName)}].

Erlang code.

-define(AST(E), (list_to_atom("Elixir.Piper.Command.Ast." ++ E))).

-export([parse_arg/1]).

parse_arg(Arg) ->
  case piper_arg_lexer:tokenize(binary_to_list(Arg)) of
    {ok, Tokens, _} ->
      parse(Tokens);
    Error ->
      Error
  end.

extract({_, _, Value}) -> Value.
value({_, _, Value}) -> list_to_binary(Value).

token_to_string({_, _, Value}) ->
  list_to_binary(Value).

token_to_integer({_, _, Value}) ->
  erlang:list_to_integer(Value).
