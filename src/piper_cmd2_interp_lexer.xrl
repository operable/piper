Definitions.

INTERP_VALUE                    = \${([^\${}]|\\\$|\\{|\\})+}
TEXT                            = (\\\^.|\\.|[^\$])+
VAR_REF                         = \$([a-zA-Z0-9_\[\]\.]+)

Rules.

{VAR_REF}                       : {token, {text, ?advance_count(TokenChars), TokenChars}}.
{INTERP_VALUE}                  : {token, {interp_value, ?advance_count(TokenChars), expr_text(TokenChars)}}.
{TEXT}                          : {token, {text, ?advance_count(TokenChars), TokenChars}}.

Erlang code.

-include("piper_cmd2_lexer.hrl").

expr_text(Text) ->
  [$$|re:replace(Text, "(^\\${|}$)", "", [{return, list}, global])].
