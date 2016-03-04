Terminals

% Datatypes
integer float bool string datum emoji variable

% Notation
shortopt longopt colon equals pipe iff redir_one redir_multi.

Nonterminals

pipeline

invocation_chain invocation name arg args

redir redir_targets redir_target

short_option long_option

var_expr

any.

Rootsymbol pipeline.

pipeline ->
  invocation_chain : '$1'.

invocation_chain ->
  invocation pipe invocation_chain : ?AST("InvocationConnector"):new('$2', '$1', '$3').
invocation_chain ->
  invocation iff invocation_chain : ?AST("InvocationConnector"):new('$2', '$1', '$3').
invocation_chain ->
  invocation : '$1'.

invocation ->
  name args: ?AST("Invocation"):new('$1', [{args, '$2'}]).
invocation ->
  name args redir : ?AST("Invocation"):new('$1', [{args, '$2'}, {redir, '$3'}]).

invocation ->
  name : ?AST("Invocation"):new('$1').
invocation ->
  name redir : ?AST("Invocation"):new('$1', [{redir, '$2'}]).

redir ->
  redir_one redir_target : ?AST("Redirect"):new('$1', '$2').
redir ->
  redir_multi redir_targets : ?AST("Redirect"):new('$1', '$2').

redir_targets ->
  redir_target : ['$1'].
redir_targets ->
  redir_target redir_targets : ['$1'] ++ '$2'.

redir_target ->
  string : ?AST("String"):new('$1').
redir_target ->
  datum : ?AST("String"):new('$1').

name ->
  string colon string : ?AST("Name"):new([{bundle, '$1'}, {entity, '$3'}]).
name ->
  string colon emoji : ?AST("Name"):new([{bundle, '$1'}, {entity, '$3'}]).
name ->
  string : ?AST("Name"):new([{entity, '$1'}]).
name ->
  emoji: ?AST("Name"):new([{entity, '$1'}]).

args ->
  arg : ['$1'].
args ->
  arg args : ['$1'] ++ '$2'.

arg ->
  short_option : '$1'.
arg ->
  long_option : '$1'.
arg ->
  var_expr : '$1'.
arg ->
  any : '$1'.

short_option ->
  shortopt string equals any : Name = ?AST("String"):new('$2'),
                               ?AST("Option"):new([{name, Name}, {value, '$4'},
                                                   {type, short}]).
short_option ->
  shortopt string equals var_expr : Name = ?AST("String"):new('$2'),
                                    ?AST("Option"):new([{name, Name}, {value, '$4'},
                                                        {type, short}]).
short_option ->
  shortopt string equals string colon string : Name = ?AST("String"):new('$2'),
                                               ?AST("Option"):new([{name, Name},
                                                                   {value, merge_strings(['$4', '$5', '$6'])},
                                                                   {type, short}]).
short_option ->
  shortopt string : Name = ?AST("String"):new('$2'),
                           ?AST("Option"):new([{name, Name}, {type, short}]).


long_option ->
  longopt string equals any : Name = ?AST("String"):new('$2'),
                              ?AST("Option"):new([{name, Name}, {value, '$4'},
                                                  {type, long}]).
long_option ->
  longopt string equals var_expr : Name = ?AST("String"):new('$2'),
                                   ?AST("Option"):new([{name, Name}, {value, '$4'},
                                                       {type, long}]).
long_option ->
  longopt string equals string colon string : Name = ?AST("String"):new('$2'),
                                              ?AST("Option"):new([{name, Name},
                                                                  {value, merge_strings(['$4', '$5', '$6'])},
                                                                  {type, long}]).
long_option ->
  longopt string : Name = ?AST("String"):new('$2'),
                   ?AST("Option"):new([{name, Name}, {type, long}]).

var_expr ->
  variable : ?AST("Variable"):new('$1').

any ->
  integer : ?AST("Integer"):new('$1').
any ->
  float : ?AST("Float"):new('$1').
any ->
  bool : ?AST("Bool"):new('$1').
any ->
  string: ?AST("String"):new('$1').
any ->
  datum: ?AST("String"):new('$1').

Erlang code.

-export([scan_and_parse/1,
         scan_and_parse/2]).

-define(AST(E), (list_to_atom("Elixir.Piper.Command.Ast2." ++ E))).

scan_and_parse(Text, Opts) when is_list(Opts) ->
  Resolver = proplists:get_value(command_resolver, Opts),
  erlang:put(cc_resolver, Resolver),
  scan_and_parse(Text).

scan_and_parse(Text) when is_binary(Text) ->
  scan_and_parse(binary_to_list(Text));
scan_and_parse(Text) ->
  case piper_cmd_lexer:tokenize(Text) of
    {ok, Tokens} ->
      parse(Tokens);
    Error ->
      Error
  end.

merge_strings([{_, Pos, _}|_]=Strings) ->
  Strings1 = [Value || {_, _, Value} <- Strings],
  ?AST("String"):new(Pos, iolist_to_binary(Strings1)).