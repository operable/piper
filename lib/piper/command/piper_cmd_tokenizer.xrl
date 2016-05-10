Definitions.

DQUOTED_STRING             = "(\\\^.|\\.|[^"])*"
SQUOTED_STRING             = '(\\\^.|\\.|[^'])*'
STRING                     = [^"'\s\n\r]+
WS                         = \s
NEWLINE                    = (\n|\r\n)

Rules.

{SQUOTED_STRING}           : advance_count(length(TokenChars)), {token, {quoted_string, position(), TokenChars}}.
{DQUOTED_STRING}           : advance_count(length(TokenChars)), {token, {quoted_string, position(), TokenChars}}.
{STRING}                   : advance_count(length(TokenChars)), {token, {string, position(), TokenChars}}.
{WS}                       : advance_count(length(TokenChars)), skip_token.
{NEWLINE}+                 : advance_line(TokenLine), skip_token.


Erlang code.

-export([init/0,
         tokenize/1]).

tokenize(Text) when is_binary(Text) ->
  tokenize(binary_to_list(Text));
tokenize(Text) when is_list(Text) ->
  case string(Text) of
    {ok, Tokens, _} ->
      {ok, Tokens};
    {error, {_, _, {illegal, Bad}}, _} ->
      Pos = string:str(Text, Bad),
      {error, {unexpected_input, Pos, Bad}};
    Error ->
      Error
  end.

init() ->
  {ok, Context} = 'Elixir.Piper.Command.ParseContext':start_link(1),
  erlang:put(piper_cp_context, Context),
  ok.

position() ->
  case erlang:get(piper_cp_context) of
    undefined ->
      {0, 0};
    Context ->
      'Elixir.Piper.Command.ParseContext':position(Context)
  end.

advance_line(TokenLine) ->
  case erlang:get(piper_cp_context) of
    undefined ->
      ok;
    Context ->
      'Elixir.Piper.Command.ParseContext':start_line(Context, TokenLine)
  end.

advance_count(Count) ->
  case erlang:get(piper_cp_context) of
    undefined ->
      ok;
    Context ->
      'Elixir.Piper.Command.ParseContext':advance_count(Context, Count)
  end.
