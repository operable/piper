Definitions.

EQUALS                     = =
LBRACKET                   = \[
RBRACKET                   = \]
OPT_NAME                   = (\-|\-\-)+[a-zA-Z0-9]+[a-zA-Z0-9_-]*
FLOAT                      = (\+[0-9]+\.[0-9]+|\-[0-9]+\.[0-9]+|[0-9]+\.[0-9]+)
VAR                        = \$[a-zA-Z]+[a-zA-Z0-9_]*
INTEGER                    = (\+[0-9]+|\-[0-9]+|[0-9]+)
DQUOTED_STRING             = "(\\\^.|\\.|[^"])*"
SQUOTED_STRING             = '(\\\^.|\\.|[^'])*'
STRING                     = (\\\^.|\\.|[^"'=\-\s\[\]\$])+

Rules.

{OPT_NAME}                 : advance_count(TokenChars), {token, {opt_name, metadata(), TokenChars}}.
{DOT}                      : advance_count(TokenChars), {token, {dot, metadata(), "."}}.
{LBRACKET}                 : advance_count(TokenChars), {token, {lbracket, metadata(), "["}}.
{RBRACKET}                 : advance_count(TokenChars), {token, {rbracket, metadata(), "]"}}.
{EQUALS}                   : advance_count(TokenChars), {token, {equals, metadata(), "="}}.
{VAR}                      : advance_count(TokenChars), {token, {variable, metadata(), TokenChars}}.
{FLOAT}                    : advance_count(TokenChars), {token, {float, metadata(), TokenChars}}.
{INTEGER}                  : advance_count(TokenChars), {token, {integer, metadata(), TokenChars}}.
{DQUOTED_STRING}           : advance_count(TokenChars), {token, {string, metadata(), TokenChars}}.
{SQUOTED_STRING}           : advance_count(TokenChars), {token, {string, metadata(), TokenChars}}.
{STRING}                   : advance_count(TokenChars), string_or_property_name(TokenChars).

Erlang code.

-export([tokenize/1]).

tokenize(Text) when is_binary(Text) ->
  tokenize(binary_to_list(Text));
tokenize(Text) ->
  string(Text).

metadata() ->
  [{position, position()}].

advance_count(TokenChars) ->
  case erlang:get(piper_cp_context) of
    undefined ->
      ok;
    Context ->
      Count = length(TokenChars),
      Context = erlang:get(piper_cp_context),
      'Elixir.Piper.Command.ParseContext':advance_count(Context, Count)
  end.

position() ->
  case erlang:get(piper_cp_context) of
    undefined ->
      {0, 0};
    Context ->
      'Elixir.Piper.Command.ParseContext':position(Context)
  end.

string_or_property_name([$.|_]=TokenChars) ->
  {token, {property_name, metadata(), TokenChars}};
string_or_property_name(TokenChars) ->
  {token, {string, metadata(), TokenChars}}.
