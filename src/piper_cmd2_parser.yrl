Terminals

%% Notation
pipe iff redir_multi redir_one

%% Types
text squoted_text dquoted_text.

Nonterminals

pipeline stages invocation args redirect targets.

Rootsymbol pipeline.

pipeline ->
  stages : ?new_ast(pipeline, ['$1']).

stages ->
  invocation : ?new_ast(pipeline_stage, ['$1']).
stages ->
  invocation pipe stages : ?new_ast(pipeline_stage, ['$2', '$1', '$3']).
stages ->
  invocation iff stages : ?new_ast(pipeline_stage, ['$2', '$1', '$3']).

invocation ->
  text : Name = ?parse_token('$1', name, fun(Name) -> Name end),
         ?new_ast(invocation, [Name]).
invocation ->
  text redirect : Name = ?parse_token('$1', name, fun(Name) -> Name end),
                  ?new_ast(invocation, [Name, [{redir, '$2'}]]).

invocation ->
  text args : Name = ?parse_token('$1', name, fun(Name) -> Name end),
              ?new_ast(invocation, [Name, [{args, validate_args('$2')}]]).
invocation ->
  text args redirect : Name = ?parse_token('$1', name, fun(Name) -> Name end),
                       ?new_ast(invocation, [Name, [{args, validate_args('$2')}, {redir, '$3'}]]).

redirect ->
  redir_multi targets : ?new_ast(redirect, ['$1', '$2']).
redirect ->
  redir_one targets : ?new_ast(redirect, ['$1', '$2']).

targets ->
  text : [var_or_string('$1')].
targets ->
  squoted_text : [I || I <- [?parse_token(strip_quotes('$1'), interp, fun(Target) -> Target end)]].
targets ->
  dquoted_text : [I || I <- [?parse_token(strip_quotes('$1'), interp, fun(Target) -> Target end)]].
targets ->
  text targets : [var_or_string('$1')] ++ '$2'.
targets ->
  squoted_text targets : [I || I <- [?parse_token(strip_quotes('$1'), interp, fun(Target) -> Target end)]] ++ '$2'.
targets ->
  dquoted_text targets : [I || I <- [?parse_token(strip_quotes('$1'), interp, fun(Target) -> Target end)]] ++ '$2'.

args ->
  text : [?parse_token('$1', arg, fun(Arg) -> Arg end)].
args ->
  squoted_text : [ensure_quote_type_set(I, squote) || I <- [?parse_token(strip_quotes('$1'), interp, fun(Arg) -> Arg end)]].
args ->
  dquoted_text : [ensure_quote_type_set(I, dquote) || I <- [?parse_token(strip_quotes('$1'), interp, fun(Arg) -> Arg end)]].
args ->
  text args : [?parse_token('$1', arg, fun(Arg) -> Arg end)] ++ '$2'.
args ->
  squoted_text args : [ensure_quote_type_set(I, squote) || I <- [?parse_token(strip_quotes('$1'), interp, fun(Arg) -> Arg end)]] ++ '$2'.
args ->
  dquoted_text args : [ensure_quote_type_set(I, dquote) || I <- [?parse_token(strip_quotes('$1'), interp, fun(Arg) -> Arg end)]] ++ '$2'.

Erlang code.

-include("piper_cmd2_parser.hrl").

-export([parse_pipeline/1]).

parse_pipeline(Text) when is_binary(Text) ->
  parse_pipeline(?parser_util:elixir_string_to_list(Text));
parse_pipeline(Text) ->
  case piper_cmd2_lexer:scan(Text) of
    {ok, Tokens, _} ->
      try parse(Tokens) of
          {ok, Results} ->
            {ok, Results};
          {error, _}=Reason ->
            format_reason(Reason)
      catch
        Reason ->
          format_reason(Reason)
      end;
    {error, {_, _, Error}, _} ->
      {error, iolist_to_binary(piper_cmd2_lexer:format_error(Error))}
  end.

format_reason({error, {_, _, Reason}}) when is_list(Reason) ->
  {error, ?parser_util:list_to_elixir_string(Reason)};
format_reason({error, {_, _, Reason}}) ->
  format_reason(Reason);
format_reason(Reason) when is_map(Reason) ->
  case maps:get('__struct__', Reason) of
    'Elixir.Piper.Command.SemanticError' ->
      Reason;
    _ ->
      {error, Reason}
  end.

strip_quotes({_, Position, [$"|_]=Text}) ->
  {string, Position, re:replace(Text, "^\"|\"$", "", [{return, list}, global, unicode])};
strip_quotes({_, Position, [$'|_]=Text}) ->
  {string, Position, re:replace(Text, "^'|'$", "", [{return, list}, global, unicode])}.

text_to_string({text, Position, Value}) ->
  {string, Position, Value}.

validate_redirect_target({_, _, [$c,$h,$a,$t,$:,$/,$/|_]}=Target) ->
  Target;
validate_redirect_target({_, {Line, Col}, [$c,$h,$a,$t,$:|_]}) ->
  return_error({Line, Col}, "URL redirect targets must begin with chat://.");
validate_redirect_target(Target) -> Target.

validate_args(Args) ->
  validate_args(Args, []).

validate_args([], Accum) ->
  lists:reverse(Accum);
validate_args([H|T], Accum) when is_map(H) ->
  case maps:find('__struct__', H) of
    {ok, 'Elixir.Piper.Command.Ast.Option'} ->
      case maps:get(value, H) of
        next_arg ->
          case T of
            [Arg|T1] ->
              H1 = maps:put(value, Arg, H),
              validate_args(T1, [H1|Accum]);
            _ ->
              return_error({0, 0}, io_lib:format("Missing value for option '~p'", [maps:get(name, H)]))
          end;
        _ ->
          validate_args(T, [H|Accum])
      end;
    _ ->
      validate_args(T, [H|Accum])
  end.

ensure_quote_type_set(Value, QuoteType) ->
  case maps:find(quote_type, Value) of
    error ->
      Value;
    {ok, _} ->
      maps:put(quote_type, QuoteType, Value)
  end.

var_or_string(Token) ->
    try ?parse_token(Token, var, fun(Var) -> Var end) of
        Var ->
            Var
    catch
        _Reason ->
            ?new_ast(string, [text_to_string(validate_redirect_target(Token))])
    end.
