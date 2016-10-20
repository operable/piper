Definitions.

EQ                     = =
INTEGER                = (\-)?[0-9]+
FLOAT                  = (\-)?[0-9]+\.[0-9]+
BOOL                   = true|false
SHORT_OPTION           = \-[a-zA-Z0-9]
LONG_OPTION            = \-\-[a-zA-Z0-9_\-]+
TEXT                   = ([^\-=]).*
DQUOTED_TEXT           = "(\\\^.|\\.|[^"])*"
SQUOTED_TEXT           = '(\\\^.|\\.|[^'])*'


Rules.

{EQ}                   : {token, {equals, ?advance_count(TokenChars), "="}}.
{INTEGER}              : {token, {integer, ?advance_count(TokenChars), TokenChars}}.
{FLOAT}                : {token, {float, ?advance_count(TokenChars), TokenChars}}.
{BOOL}                 : {token, {bool, ?advance_count(TokenChars), TokenChars}}.
{SHORT_OPTION}         : {token, {short_option, ?advance_count(TokenChars), TokenChars}}.
{LONG_OPTION}          : {token, {long_option, ?advance_count(TokenChars), TokenChars}}.
{DQUOTED_TEXT}         : {token, {dquoted_text, ?advance_count(TokenChars), TokenChars}}.
{SQUOTED_TEXT}         : {token, {squoted_text, ?advance_count(TokenChars), TokenChars}}.
{TEXT}                 : {token, {text, ?advance_count(TokenChars), TokenChars}}.

Erlang code.

-include("piper_cmd2_lexer.hrl").
