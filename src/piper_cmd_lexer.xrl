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
VERSION                    = [0-9]+\.[0-9]+\.[0-9]+
FLOAT                      = (\+[0-9]+\.[0-9]+|\-[0-9]+\.[0-9]+|[0-9]+\.[0-9]+)
INTEGER                    = (\+[0-9]+|\-[0-9]+|[0-9]+)
NAME                       = [a-zA-Z]+[a-zA-Z0-9_\-\.]*
DQUOTED_STRING             = "(\\\^.|\\.|[^"])*"
SQUOTED_STRING             = '(\\\^.|\\.|[^'])*'
DATUM                      = [^\s\[\]\$\-"':\.=\n\r]+[^\s\[\]\$"':\.=\n\r]*
WS                         = \s
NEWLINE                    = (\n|\r\n)

Rules.

{PIPE}                     : {token, {pipe, advance_count(length(TokenChars)), "|"}}.
{IFF}                      : {token, {iff, advance_count(length(TokenChars)), "&&"}}.
{REDIR_MULTI}              : {token, {redir_multi, advance_count(length(TokenChars)), "*>"}}.
{REDIR_ONE}                : {token, {redir_one, advance_count(length(TokenChars)), ">"}}.
{LBRACKET}                 : {token, {lbracket, advance_count(length(TokenChars)), "["}}.
{RBRACKET}                 : {token, {rbracket, advance_count(length(TokenChars)), "]"}}.
{WS}{COLON}                : {token, {bad_colon, advance_count(length(TokenChars)), ":"}}.
{COLON}{WS}                : {token, {bad_colon, advance_count(length(TokenChars)), ":"}}.
{COLON}                    : {token, {colon, advance_count(length(TokenChars)), ":"}}.
{SLASH}                    : {token, {slash, advance_count(length(TokenChars)), "/"}}.
{EQUALS}                   : {token, {equals, advance_count(length(TokenChars)), "="}}.
{DOT}                      : {token, {dot, advance_count(length(TokenChars)), "."}}.
{WS}{SLACK_EMOJI}          : {token, {emoji, advance_count(length(TokenChars)), tl(TokenChars)}}.
{SLACK_EMOJI}              : {token, {emoji, advance_count(length(TokenChars)), TokenChars}}.
{HIPCHAT_EMOJI}            : {token, {emoji, advance_count(length(TokenChars)), TokenChars}}.
{VAR}                      : {token, {variable, advance_count(length(TokenChars)), tl(TokenChars)}}.
{TRUE}                     : {token, {bool, advance_count(length(TokenChars)), "true"}}.
{FALSE}                    : {token, {bool, advance_count(length(TokenChars)), "false"}}.
{VERSION}                  : {token, {string, advance_count(length(TokenChars)), TokenChars}}.
{FLOAT}                    : {token, {float, advance_count(length(TokenChars)), TokenChars}}.
{INTEGER}                  : {token, {integer, advance_count(length(TokenChars)), TokenChars}}.
{DOUBLE_DASH}              : {token, {longopt, advance_count(length(TokenChars)), "--"}}.
{SINGLE_DASH}              : {token, {shortopt, advance_count(length(TokenChars)), "-"}}.
{NAME}                     : {token, {string, advance_count(length(TokenChars)), TokenChars}}.
{DQUOTED_STRING}           : {token, {string, advance_count(length(TokenChars)), clean_dquotes(TokenChars)}}.
{SQUOTED_STRING}           : {token, {string, advance_count(length(TokenChars)), clean_squotes(TokenChars)}}.
{DATUM}                    : {token, {datum, advance_count(length(TokenChars)), TokenChars}}.
{WS}                       : skip_token.
{NEWLINE}+                 : advance_line(TokenLine), skip_token.

Erlang code.

-export([tokenize/1,
         tokenize/2]).

%% Should only be called by test code
%% Have to use this Mix env inspection hack since Mix doesn't compile Erlang code
%% with TEST defined as per usual Erlang practice.
tokenize(Text, MaxDepth) ->
  case 'Elixir.Mix':env() of
    test ->
      Opts = 'Elixir.Piper.Command.ParserOptions':defaults(),
      Opts1 = maps:put(use_legacy_parser, true, Opts),
      Opts2 = maps:put(expansion_limit, MaxDepth, Opts1),
      {ok, Context} = 'Elixir.Piper.Command.ParseContext':start_link(Opts2),
      try tokenize(Text) of
        Result -> Result
      after
        'Elixir.Piper.Command.ParseContext':stop(Context)
      end;
    EnvName ->
      throw({bad_mix_env, EnvName})
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

advance_line(TokenLine) ->
  Context = 'Elixir.Piper.Command.ParseContext':current(),
  'Elixir.Piper.Command.ParseContext':start_line(Context, TokenLine).

advance_count(Count) ->
  Context = 'Elixir.Piper.Command.ParseContext':current(),
  'Elixir.Piper.Command.ParseContext':advance_count(Context, Count).

clean_dquotes(String) ->
  String1 = re:replace(String, "^\"", "", [{return, list}]),
  re:replace(String1, "\"$", "", [{return, list}]).

clean_squotes(String) ->
  String1 = re:replace(String, "^'", "", [{return, list}]),
  re:replace(String1, "'$", "", [{return, list}]).
