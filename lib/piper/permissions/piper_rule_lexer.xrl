Definitions.

RESERVED                        = (when|with|must|have|command|true|false|any|all|is)
BARE_ARG                        = arg
AGGREGATE_ARGS                  = args
INDEXED_ARG                     = arg\[([0-9])+\]
OPTION                          = option
AGGREGATE_OPTIONS               = options
OPERATORS                       = (<|>|=<|>=|==|!=|and|or|not|in)
NAME                            = [a-zA-Z]+[a-zA-Z0-9_\-]*
SLACK_EMOJI                     = :[a-zA-Z]+[a-zA-Z0-9_\-]*:
HIPCHAT_EMOJI                   = \([a-zA-Z]+[a-zA-Z0-9_\-]*\)
INTEGER                         = ([0-9])+
FLOAT                           = ([0-9])+\.([0-9])+
STRING                          = ([a-zA-Z0-9_\-])+
LPAREN                          = \(
RPAREN                          = \)
LBRACKET                        = \[
RBRACKET                        = \]
COMMA                           = ,
COLON                           = :
REGEX                           = \/(\\\^.|\\.|[^\/])*\/
WS                              = \s
NEWLINE                         = (\n|\r\n)

Rules.

{RESERVED}                      : advance_count(length(TokenChars)), {token, reserved_word(TokenChars)}.
{INDEXED_ARG}                   : advance_count(length(TokenChars)), {token, {arg, position(), decode_arg_index(TokenChars)}}.
{BARE_ARG}                      : advance_count(length(TokenChars)), {token, {arg, position(), nil}}.
{AGGREGATE_ARGS}                : advance_count(length(TokenChars)), {token, {arg, position(), nil}}.
{OPTION}                        : advance_count(length(TokenChars)), {token, {option, position(), nil}}.
{AGGREGATE_OPTIONS}             : advance_count(length(TokenChars)), {token, {option, position(), nil}}.
{OPERATORS}                     : advance_count(length(TokenChars)), {token, build_operator(TokenChars)}.
{LBRACKET}                      : advance_count(length(TokenChars)), {token, {lbracket, position(), "["}}.
{RBRACKET}                      : advance_count(length(TokenChars)), {token, {rbracket, position(), "]"}}.
{COMMA}                         : advance_count(length(TokenChars)), {token, {comma, position(), ","}}.
{REGEX}                         : advance_count(length(TokenChars)), {token, {regex, position(), build_regex(TokenChars)}}.
{SLACK_EMOJI}                   : advance_count(length(TokenChars)), {token, {emoji, position(), TokenChars}}.
{HIPCHAT_EMOJI}                 : advance_count(length(TokenChars)), {token, {emoji, position(), TokenChars}}.
{LPAREN}                        : advance_count(length(TokenChars)), {token, {lparen, position(), "("}}.
{RPAREN}                        : advance_count(length(TokenChars)), {token, {rparen, position(), ")"}}.
{COLON}                         : advance_count(length(TokenChars)), {token, {colon, position(), ":"}}.
{NAME}                          : advance_count(length(TokenChars)), {token, {name, position(), TokenChars}}.
{FLOAT}                         : advance_count(length(TokenChars)), {token, {float, position(), list_to_float(TokenChars)}}.
{INTEGER}                       : advance_count(length(TokenChars)), {token, {integer, position(), list_to_integer(TokenChars)}}.
"(\\\^.|\\.|[^"])*"             : advance_count(length(TokenChars)), {token, {dqstring, position(), clean_string(TokenChars)}}.
'(\\\^.|\\.|[^'])*'             : advance_count(length(TokenChars)), {token, {sqstring, position(), clean_string(TokenChars)}}.
{STRING}                        : advance_count(length(TokenChars)), {token, {string, position(), TokenChars}}.
{WS}+                           : advance_count(length(TokenChars)), skip_token().
{NEWLINE}+                      : advance_line(TokenLine), skip_token().

Erlang code.

-export([tokenize/1]).

tokenize(Text) when is_binary(Text) ->
  tokenize(binary_to_list(Text));
tokenize(Text) when is_list(Text) ->
  init(),
  case string(Text) of
    {ok, Tokens, _} ->
      {ok, Tokens};
    Error ->
      Error
  end.

init() ->
  erlang:put(br_lexer_line_count, 1),
  erlang:put(br_lexer_last_char, 0),
  erlang:put(br_lexer_char_count, 0).

clean_string([$'|Str]) ->
  re:replace(Str, "'$", "", [global, {return, list}]);
clean_string([$"|Str]) ->
  re:replace(Str, "\"$", "", [global, {return, list}]).

position() ->
  {get_with_default(br_lexer_line_count, 1),
   get_with_default(br_lexer_char_count, 0) - get_with_default(br_lexer_last_char, 0)}.

advance_line(TokenLine) ->
  erlang:put(br_lexer_line_count, TokenLine),
  erlang:put(br_lexer_last_char, 0),
  erlang:put(br_lexer_char_count, 0).

advance_count(Count) ->
  erlang:put(br_lexer_last_char, Count),
  set_or_add(br_lexer_char_count, Count).

get_with_default(Key, Default) ->
  case erlang:get(Key) of
    undefined ->
      Default;
    Value ->
      Value
  end.

set_or_add(Key, Value) ->
  case erlang:get(Key) of
    undefined ->
      erlang:put(Key, Value);
    OldValue ->
      erlang:put(Key, OldValue + Value)
  end.

skip_token() -> skip_token.

reserved_word("true") ->
  {boolean, position(), true};
reserved_word("false") ->
  {boolean, position(), false};
reserved_word(Word) ->
  {list_to_atom(Word), position(), Word}.

build_operator("!=") ->
  {not_equiv, position(), "!="};
build_operator("==") ->
  {equiv, position(), "=="};
build_operator(">") ->
  {gt, position(), ">"};
build_operator("<") ->
  {lt, position(), "<"};
build_operator("=<") ->
  {lte, position(), "=<"};
build_operator(">=") ->
  {gte, position(), ">="};
build_operator("and") ->
  {'and', position(), "and"};
build_operator("or") ->
  {'or', position(), "or"};
build_operator("not") ->
  {'not', position(), "not"};
build_operator("in") ->
  {'in', position(), "in"}.

build_regex([$/|Str]) ->
  re:replace(Str, "\/$", "", [global, {return, list}]).

decode_arg_index([$a, $r, $g, $\[|Index]) ->
  list_to_integer(re:replace(Index, "]$", "", [global, {return, list}])).

