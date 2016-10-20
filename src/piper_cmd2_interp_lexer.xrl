Definitions.

INTERP_VALUE                    = \${([^\${}]|\\\$|\\{|\\})+}
TEXT                            = (\\\^.|\\.|[^\$])+
Rules.

{INTERP_VALUE}                  : {token, {interp_value, ?advance_count(TokenChars), expr_text(TokenChars)}}.
{TEXT}                          : {token, {text, ?advance_count(TokenChars), TokenChars}}.

Erlang code.

-include("piper_cmd2_lexer.hrl").

expr_text(Text) ->
  [$$|re:replace(Text, "(^\\${|}$)", "", [{return, list}, global])].
