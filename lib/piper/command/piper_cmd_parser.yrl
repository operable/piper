Terminals

% Datatypes
bool float integer string

% Notation
pipe iff redir_multi redir_one.

Nonterminals

pipeline

pipeline_stages invocation arg args

redir redir_targets redir_target.

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
  string args: ?AST("Invocation"):new('$1', [{args, '$2'}]).
invocation ->
  string args redir : ?AST("Invocation"):new('$1', [{args, '$2'}, {redir, '$3'}]).
invocation ->
  string : ?AST("Invocation"):new('$1').
invocation ->
  string redir : ?AST("Invocation"):new('$1', [{redir, '$2'}]).

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

args ->
  arg : '$1'.
args ->
  arg args : '$1' ++ '$2'.

arg ->
  integer : [?AST("Integer"):new('$1')].
arg ->
  float : [?AST("Float"):new('$1')].
arg ->
  bool : [?AST("Bool"):new('$1')].
arg ->
  string : [?AST("String"):new('$1')].

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
