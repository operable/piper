Definitions.

NAME                        = [a-z][a-zA-Z0-9_\-]*
HIPCHAT_EMOJI               = \([a-zA-Z0-9_\-\+]+\)
SLACK_EMOJI                 = :[a-zA-Z0-9_\-\+]+:
COLON                       = :
BAD_HIPCHAT_EMOJI           = \([a-zA-Z0-9_\-\+]+

Rules.

{NAME}                      : {token, {name, ?advance_count(TokenChars), TokenChars}}.
{HIPCHAT_EMOJI}             : {token, {emoji, ?advance_count(TokenChars), TokenChars}}.
{SLACK_EMOJI}               : {token, {emoji, ?advance_count(TokenChars), TokenChars}}.
{COLON}                     : {token, {colon, ?advance_count(TokenChars), ":"}}.
{BAD_HIPCHAT_EMOJI}         : {error, ["HipChat emoji missing paren: \"", TokenChars, "\""]}.


Erlang code.

-include("piper_cmd2_lexer.hrl").
