Definitions.

PIPE                       = \|
IFF                        = &&
REDIR_MULTI                = \*>
REDIR_ONE                  = >
TEXT                       = ([^\"'\s])+
DQUOTED_TEXT               = "(\\\^.|\\.|[^"])*"
BAD_DQUOTED_TEXT           = "(\\\^.|\\.|[^"])*
SQUOTED_TEXT               = '(\\\^.|\\.|[^'])*'
BAD_SQUOTED_TEXT           = '(\\\^.|\\.|[^'])*
WS                         = \s
NEWLINE                    = (\n|\r\n)

Rules.

{PIPE}                     : {token, {pipe, ?advance_count(TokenChars), "|"}}.
{IFF}                      : {token, {iff, ?advance_count(TokenChars), "&&"}}.
{REDIR_MULTI}              : {token, {redir_multi, ?advance_count(TokenChars), "*>"}}.
{REDIR_ONE}                : {token, {redir_one, ?advance_count(TokenChars), ">"}}.
{DQUOTED_TEXT}             : {token, {dquoted_text, ?advance_count(TokenChars), TokenChars}}.
{BAD_DQUOTED_TEXT}         : {error, ["Missing double quote: ", TokenChars]}.
{SQUOTED_TEXT}             : {token, {squoted_text, ?advance_count(TokenChars), TokenChars}}.
{BAD_SQUOTED_TEXT}         : {error, ["Missing single quote: ", TokenChars]}.
{TEXT}                     : {token, {text, ?advance_count(TokenChars), TokenChars}}.
{WS}                       : ?advance_count(TokenChars), skip_token.
{NEWLINE}                  : ?advance_line(TokenLine), skip_token.

Erlang code.

-include("piper_cmd2_lexer.hrl").

-export([scan/1,
         apply_fixups/1]).

scan(String) ->
  case string(String) of
    {ok, Tokens, N} ->
      {ok, apply_fixups(Tokens), N};
    Error ->
      Error
  end.

apply_fixups(Tokens) -> apply_fixups(Tokens, []).

apply_fixups([], Accum) -> lists:reverse(Accum);
apply_fixups([{text, T1Pos, T1Text}=T1, {Quoted, _, QuotedValue}=QT, {text, _, T2Text}=T2|T], Accum) when Quoted == squoted_text;
                                                                                                          Quoted == dquoted_text ->
  case re:run(T1Text, "\\[$", [{capture, none}]) of
    match ->
      case re:run(T2Text, "^\\]", [{capture, none}]) of
        match ->
          Updated = {text, T1Pos, T1Text ++ QuotedValue ++ T2Text},
          apply_fixups([Updated|T], Accum);
        nomatch ->
          apply_fixups([QT, T2|T], [T1|Accum])
      end;
    nomatch ->
      case re:run(T1Text, "\\.$", [{capture, none}]) of
        match ->
          Updated = {text, T1Pos, T1Text ++ QuotedValue},
          apply_fixups([Updated, T2|T], Accum);
        nomatch ->
          apply_fixups([QT, T2|T], [T1|Accum])
      end
  end;
apply_fixups([{text, T1Pos, T1Text}=T1, {TextType, _, T2Text}=T2|T], Accum) when TextType == text;
                                                                                 TextType == squoted_text;
                                                                                 TextType == dquoted_text ->
  case re:run(T2Text, "(^\\.|^\\[)", [{capture, none}]) of
    match ->
      Updated = {text, T1Pos, T1Text ++ T2Text},
      apply_fixups([Updated|T], Accum);
    nomatch ->
      apply_fixups([T2|T], [T1|Accum])
  end;
apply_fixups([H|T], Accum) ->
  apply_fixups(T, [H|Accum]).
