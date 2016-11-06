Definitions.

VARIABLE               = \$[a-zA-Z]([a-zA-Z0-9_\-])*
LBRACKET               = \[
RBRACKET               = \]
DOT                    = \.
INTEGER                = [0-9]+
TEXT                   = ([^\$\[\]\.])+

Rules.

{VARIABLE}             : {token, {variable, ?advance_count(TokenChars), TokenChars}}.
{LBRACKET}             : {token, {lbracket, ?advance_count(TokenChars), "["}}.
{RBRACKET}             : {token, {rbracket, ?advance_count(TokenChars), "]"}}.
{DOT}                  : {token, {dot, ?advance_count(TokenChars), "."}}.
{INTEGER}              : {token, {integer, ?advance_count(TokenChars), TokenChars}}.
{TEXT}                 : {token, {text, ?advance_count(TokenChars), TokenChars}}.

Erlang code.

-export([possible_varexpr/1]).

-include("piper_cmd2_lexer.hrl").

possible_varexpr({_, _, Value}) ->
  re:run(Value, "^\\$", [{capture, none}, unicode]) == match.
