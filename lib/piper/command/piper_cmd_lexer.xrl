Definitions.

PIPE                       = \|
IFF                        = &&
REDIR_MULTI                = \*>
REDIR_ONE                  = >
TRUE                       = (true|TRUE)
FALSE                      = (false|FALSE)
FLOAT                      = (\+[0-9]+\.[0-9]+|\-[0-9]+\.[0-9]+|[0-9]+\.[0-9]+)
INTEGER                    = (\+[0-9]+|\-[0-9]+|[0-9]+)
NAME                       = [a-zA-Z0-9]+[a-zA-Z0-9_\-]*
STRING                     = [^"'\s\n\r]+

Rules.

{PIPE}                     : advance_count(length(TokenChars)), {token, {pipe, metadata(), "|"}}.
{IFF}                      : advance_count(length(TokenChars)), {token, {iff, metadata(), "&&"}}.
{REDIR_MULTI}              : advance_count(length(TokenChars)), {token, {redir_multi, metadata(), "*>"}}.
{REDIR_ONE}                : advance_count(length(TokenChars)), {token, {redir_one, metadata(), ">"}}.
{TRUE}                     : advance_count(length(TokenChars)), {token, {bool, metadata(), "true"}}.
{FALSE}                    : advance_count(length(TokenChars)), {token, {bool, metadata(), "false"}}.
{FLOAT}                    : advance_count(length(TokenChars)), {token, {float, metadata(float), TokenChars}}.
{INTEGER}                  : advance_count(length(TokenChars)), {token, {integer, metadata(integer), TokenChars}}.
{NAME}:{NAME}              : advance_count(length(TokenChars)), {token, {string, metadata(qualified_name), TokenChars}}.
{STRING}                   : advance_count(length(TokenChars)), {token, {string, metadata(), TokenChars}}.

%% Terminals
%% pipe iff redir_multi redir_one equals
%% bool float integer string

Erlang code.

-export([tokenize/1,
         tokenize/2]).

tokenize(Text, MaxDepth) when is_binary(Text) ->
  tokenize(binary_to_list(Text), MaxDepth);
tokenize(Text, MaxDepth) when is_list(Text) ->
  init(MaxDepth),
  tokenize(Text).

tokenize(Text) when is_binary(Text) ->
  tokenize(binary_to_list(Text));
tokenize(Text) when is_list(Text) ->
  case piper_cmd_tokenizer:tokenize(Text) of
    {ok, Tokens} ->
      {ok, lists:flatmap(fun(Token) -> lex_token(Token) end, Tokens)};
    Error ->
      Error
  end.

lex_token({string, Pos, Text}) ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':set_position(Context, Pos),
  case string(Text) of
    {ok, Tokens, _} ->
      Tokens;
    Error ->
      throw(Error)
  end;
lex_token({quoted_string, Pos, Value}) -> [{string, [{position, Pos}], list_to_binary(Value)}].

init(MaxDepth) ->
  {ok, Context} = 'Elixir.Piper.Command.ParseContext':start_link(MaxDepth),
  erlang:put(piper_cp_context, Context).

position() ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':position(Context).

advance_count(Count) ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':advance_count(Context, Count).

metadata() ->
  [{position, position()}].

metadata(TypeHint) when is_atom(TypeHint) ->
  [{position, position()},
   {hint, TypeHint}].
