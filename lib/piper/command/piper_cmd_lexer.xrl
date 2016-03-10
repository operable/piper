Definitions.

PIPE                       = \|
IFF                        = &&
REDIR_MULTI                = \*>
REDIR_ONE                  = >
LBRACKET                   = \[
RBRACKET                   = \]
DOUBLE_DASH                = \-\-
SINGLE_DASH                = \-
COLON                      = :
EQUALS                     = =
DOT                        = \.
SLACK_EMOJI                = :[a-zA-Z]+[a-zA-Z0-9_\-]*:
HIPCHAT_EMOJI              = \([a-zA-Z]+[a-zA-Z0-9_\-]*\)
VAR                        = \$[a-zA-Z]+[a-zA-Z0-9_]*
TRUE                       = (true|TRUE)
FALSE                      = (false|FALSE)
FLOAT                      = (\+[0-9]+\.[0-9]+|\-[0-9]+\.[0-9]+|[0-9]+\.[0-9]+)
INTEGER                    = (\+[0-9]+|\-[0-9]+|[0-9]+)
NAME                       = [a-zA-Z]+[a-zA-Z0-9_\-]*
DQUOTED_STRING             = "(\\\^.|\\.|[^"])*"
SQUOTED_STRING             = '(\\\^.|\\.|[^'])*'
DATUM                      = [^\s\[\]\$\-"':\.=\n\r]+[^\s\[\]\$"':\.=\n\r]*
WS                         = \s
NEWLINE                    = (\n|\r\n)

Rules.

{PIPE}                     : advance_count(length(TokenChars)), {token, {pipe, position(), "|"}}.
{IFF}                      : advance_count(length(TokenChars)), {token, {iff, position(), "&&"}}.
{REDIR_MULTI}              : advance_count(length(TokenChars)), {token, {redir_multi, position(), "*>"}}.
{REDIR_ONE}                : advance_count(length(TokenChars)), {token, {redir_one, position(), ">"}}.
{LBRACKET}                 : advance_count(length(TokenChars)), {token, {lbracket, position(), "["}}.
{RBRACKET}                 : advance_count(length(TokenChars)), {token, {rbracket, position(), "]"}}.
{COLON}                    : advance_count(length(TokenChars)), {token, {colon, position(), ":"}}.
{EQUALS}                   : advance_count(length(TokenChars)), {token, {equals, position(), "="}}.
{DOT}                      : advance_count(length(TokenChars)), {token, {dot, position(), "."}}.
{SLACK_EMOJI}              : advance_count(length(TokenChars)), {token, {emoji, position(), TokenChars}}.
{HIPCHAT_EMOJI}            : advance_count(length(TokenChars)), {token, {emoji, position(), TokenChars}}.
{VAR}                      : advance_count(length(TokenChars)), {token, {variable, position(), tl(TokenChars)}}.
{TRUE}                     : advance_count(length(TokenChars)), {token, {bool, position(), "true"}}.
{FALSE}                    : advance_count(length(TokenChars)), {token, {bool, position(), "false"}}.
{FLOAT}                    : advance_count(length(TokenChars)), {token, {float, position(), TokenChars}}.
{INTEGER}                  : advance_count(length(TokenChars)), {token, {integer, position(), TokenChars}}.
{DOUBLE_DASH}              : advance_count(length(TokenChars)), {token, {longopt, position(), "--"}}.
{SINGLE_DASH}              : advance_count(length(TokenChars)), {token, {shortopt, position(), "-"}}.
{NAME}                     : advance_count(length(TokenChars)), {token, {string, position(), TokenChars}}.
{DQUOTED_STRING}           : advance_count(length(TokenChars)), {token, {string, position(), clean_dquotes(TokenChars)}}.
{SQUOTED_STRING}           : advance_count(length(TokenChars)), {token, {string, position(), clean_squotes(TokenChars)}}.
{DATUM}                    : advance_count(length(TokenChars)), {token, {datum, position(), TokenChars}}.
{WS}+                      : advance_count(length(TokenChars)), skip_token.
{NEWLINE}+                 : advance_line(TokenLine), skip_token.

Erlang code.

-export([tokenize/1,
         tokenize/2]).

tokenize(Text, MaxDepth) when is_binary(Text) ->
  tokenize(binary_to_list(Text), MaxDepth);
tokenize(Text, MaxDepth) when is_list(Text) ->
  init(MaxDepth),
  case string(Text) of
    {ok, Tokens, _} ->
      {ok, Tokens};
    {error, {_, _, {illegal, Bad}}, _} ->
      Pos = string:str(Text, Bad),
      {error, {unexpected_input, Pos, Bad}};
    Error ->
      Error
  end.

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

init(MaxDepth) ->
  {ok, Context} = 'Elixir.Piper.Command.ParseContext':start_link(MaxDepth),
  erlang:put(piper_cp_context, Context).

position() ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':position(Context).

advance_line(TokenLine) ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':start_line(Context, TokenLine).

advance_count(Count) ->
  Context = erlang:get(piper_cp_context),
  'Elixir.Piper.Command.ParseContext':advance_count(Context, Count).

clean_dquotes(String) ->
  String1 = re:replace(String, "^\"", "", [{return, list}]),
  re:replace(String1, "\"$", "", [{return, list}]).

clean_squotes(String) ->
  String1 = re:replace(String, "^'", "", [{return, list}]),
  re:replace(String1, "'$", "", [{return, list}]).
