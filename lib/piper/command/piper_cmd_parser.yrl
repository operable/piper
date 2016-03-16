Terminals

% Datatypes
integer float bool string datum emoji variable

% Notation
shortopt longopt colon equals lbracket rbracket dot pipe iff redir_one redir_multi.

Nonterminals

pipeline

pipeline_stages invocation name arg args

redir redir_targets redir_target

short_option long_option

var_expr var_ops

any.

Rootsymbol pipeline.

pipeline ->
  pipeline_stages : ?AST("Pipeline"):new('$1').

pipeline_stages ->
  invocation pipe pipeline_stages : ?AST("PipelineStage"):new('$2', '$1', '$3').
pipeline_stages ->
  invocation iff pipeline_stages : ?AST("PipelineStage"):new('$2', '$1', '$3').
pipeline_stages ->
  invocation : ?AST("PipelineStage"):new('$1').

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
  emoji : ?AST("Name"):new([{entity, '$1'}]).

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
  string colon string : merge_strings(['$1', '$2', '$3']).
arg ->
  string colon emoji : merge_strings(['$1', '$2', '$3']).
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
  shortopt string equals string colon emoji : Name = ?AST("String"):new('$2'),
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
  longopt string equals string colon emoji : Name = ?AST("String"):new('$2'),
                                             ?AST("Option"):new([{name, Name},
                                                                 {value, merge_strings(['$4', '$5', '$6'])},
                                                                 {type, long}]).
long_option ->
  longopt string : Name = ?AST("String"):new('$2'),
                   ?AST("Option"):new([{name, Name}, {type, long}]).

var_expr ->
  variable : ?AST("Variable"):new('$1').
var_expr ->
  variable var_ops : ?AST("Variable"):new('$1', '$2').

var_ops ->
  lbracket integer rbracket : [{index, token_to_integer('$2')}].
var_ops ->
  lbracket string rbracket : [{key, token_to_string('$2')}].
var_ops ->
  lbracket datum rbracket : [{key, token_to_string('$2')}].
var_ops ->
  dot string : [{key, token_to_string('$2')}].
var_ops ->
  dot datum : [{key, token_to_string('$2')}].
var_ops ->
  lbracket integer rbracket var_ops : [{index, token_to_integer('$2')}] ++ '$4'.
var_ops ->
  lbracket string rbracket var_ops : [{key, token_to_string('$2')}] ++ '$4'.
var_ops ->
  lbracket datum rbracket var_ops : [{key, token_to_string('$2')}] ++ '$4'.
var_ops ->
  dot string var_ops : [{key, token_to_string('$2')}] ++ '$3'.
var_ops ->
  dot datum var_ops : [{key, token_to_string('$2')}] ++ '$3'.

any ->
  integer : ?AST("Integer"):new('$1').
any ->
  float : ?AST("Float"):new('$1').
any ->
  bool : ?AST("Bool"):new('$1').
any ->
  emoji : ?AST("String"):new('$1').
any ->
  string: ?AST("String"):new('$1').
any ->
  datum: ?AST("String"):new('$1').

Erlang code.

-export([scan_and_parse/1]).

-define(AST(E), (list_to_atom("Elixir.Piper.Command.Ast." ++ E))).

scan_and_parse(Text) when is_binary(Text) ->
  scan_and_parse(binary_to_list(Text));
scan_and_parse(Text) ->
  case piper_cmd_lexer:tokenize(Text) of
    {ok, Tokens} ->
      case parse(Tokens) of
        {ok, Ast} ->
          {ok, Ast};
        Error ->
          pp_error(Error)
      end;
    Error ->
      {error, list_to_binary([piper_cmd_lexer:format_error(Error), "."])}
  end.

pp_error({error, {_, _, ["syntax error before: ", []]}}) ->
  {error, <<"Unexpected end of input.">>};
pp_error({error, {Line, _, Message}}) when is_integer(Line) ->
  {error, list_to_binary(Message)};
pp_error({error, {{Line, Col}, _, Message}}) ->
  {error, list_to_binary(io_lib:format("(Line: ~p, Col: ~p) ~s.", [Line, Col, Message]))}.

merge_strings([{_, Pos, _}|_]=Strings) ->
  Strings1 = [Value || {_, _, Value} <- Strings],
  ?AST("String"):new(Pos, iolist_to_binary(Strings1)).

token_to_integer({integer, _, Text}) ->
  list_to_integer(Text).

token_to_string({Type, _, Text}) when Type == string orelse
                                      Type == datum ->
  list_to_binary(Text).
