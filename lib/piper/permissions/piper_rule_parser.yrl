Terminals

%% Keywords
all any arg command have is must option when with

%% Operators
and or in equiv not_equiv lt gt lte gte

%% Data types
name boolean float integer dqstring sqstring string regex emoji

%% Punctuation
colon comma lbracket rbracket lparen rparen.

Nonterminals

access_rule

command_selector command_criteria

ns_name_list ns_name_list_body ns_name

input_criterion input_criteria input_criteria_binop

permission_selector permission_criterion permission_criteria

arg_or_option arg_ref option_ref

regular_expr string_expr value value_list value_list_body.

Rootsymbol access_rule.

access_rule ->
  command_selector : ?AST("Rule"):new('$1', nil).
access_rule ->
  command_selector permission_selector : ?AST("Rule"):new('$1', '$2').

command_selector ->
  when command command_criteria : update('$3', [{left, ?AST("Var"):new(<<"command">>)}]).
command_selector ->
  when command command_criteria with input_criterion : Lhs = update('$3', [{left, ?AST("Var"):new(<<"command">>)}]),
                                                       ?AST("BinaryExpr"):new('$4', [{left, Lhs},
                                                                                     {right, '$5'}]).
permission_selector ->
  must have permission_criterion : '$3'.

permission_criterion ->
  permission_criteria : '$1'.
permission_criterion ->
  lparen permission_criterion rparen : update('$2', [{parens, true}]).
permission_criterion ->
  lparen permission_criterion rparen and permission_criterion : Lhs = update('$2', [{parens, true}]),
                                                                ?AST("ConditionalExpr"):new('$4', [{left, Lhs},
                                                                                                   {right, '$5'}]).
permission_criterion ->
  lparen permission_criterion rparen or permission_criterion : Lhs = update('$2', [{parens, true}]),
                                                               ?AST("ConditionalExpr"):new('$4', [{left, Lhs},
                                                                                                  {right, '$5'}]).
permission_criterion ->
  permission_criteria and permission_criterion : ?AST("ConditionalExpr"):new('$2', [{left, '$1'},
                                                                                   {right, '$3'}]).
permission_criterion ->
  permission_criteria or permission_criterion : ?AST("ConditionalExpr"):new('$2', [{left, '$1'},
                                                                                   {right, '$3'}]).

permission_criteria ->
  any in ns_name_list : ?AST("PermissionExpr"):new('$1', track('$3')).
permission_criteria ->
  all in ns_name_list : ?AST("PermissionExpr"):new('$1', track('$3')).
permission_criteria ->
  ns_name : verify_permission_name('$1'),
           ?AST("PermissionExpr"):new(add_permission('$1')).

command_criteria ->
  is ns_name : ?AST("BinaryExpr"):new('$1', [{right, verify_command_name('$2')}]).

input_criterion ->
  input_criteria : '$1'.
input_criterion ->
  lparen input_criterion rparen : update('$2', [{parens, true}]).
input_criterion ->
  lparen input_criterion rparen and input_criterion : Lhs = update('$2', [{parens, true}]),
                                                      ?AST("ConditionalExpr"):new('$4', [{left, Lhs}, {right, '$5'}]).
input_criterion ->
  lparen input_criterion rparen or input_criterion : Lhs = update('$2', [{parens, true}]),
                                                     ?AST("ConditionalExpr"):new('$4', [{left, Lhs}, {right, '$5'}]).
input_criterion ->
  input_criteria and input_criterion : ?AST("ConditionalExpr"):new('$2', [{left, '$1'}, {right, '$3'}]).
input_criterion ->
  input_criteria or input_criterion : ?AST("ConditionalExpr"):new('$2', [{left, '$1'}, {right, '$3'}]).

input_criteria ->
  arg_or_option input_criteria_binop value : update('$2', [{left, '$1'}, {right, '$3'}]).
input_criteria ->
  arg_or_option in value_list : ?AST("ContainExpr"):new('$2', '$1', '$3').

arg_or_option ->
  arg_ref : track('$1').
arg_or_option ->
  option_ref : track('$1').

option_ref ->
  any option : ?AST("Option"):new('$2', any).
option_ref ->
  all option : ?AST("Option"):new('$2', all).
option_ref ->
  option lbracket string rbracket : ?AST("Option"):new('$1', '$3').
option_ref ->
  option lbracket name rbracket : ?AST("Option"):new('$1', '$3').


arg_ref ->
  any arg : build_arg('$2', any).
arg_ref ->
  all arg : build_arg('$2', all).
arg_ref ->
  arg : build_arg('$1', indexed).

input_criteria_binop ->
  equiv : ?AST("BinaryExpr"):new('$1').
input_criteria_binop ->
  not_equiv : ?AST("BinaryExpr"):new('$1').
input_criteria_binop ->
  gt : ?AST("BinaryExpr"):new('$1').
input_criteria_binop ->
  lt : ?AST("BinaryExpr"):new('$1').
input_criteria_binop ->
  gte : ?AST("BinaryExpr"):new('$1').
input_criteria_binop ->
  lte : ?AST("BinaryExpr"):new('$1').

ns_name_list ->
  lbracket rbracket : ?AST("List"):new('$1', []).
ns_name_list ->
  lbracket ns_name_list_body rbracket : ?AST("List"):new('$1', '$2').

ns_name_list_body ->
  ns_name comma ns_name_list_body : [verify_permission_name('$1')] ++ '$3'.
ns_name_list_body ->
  regular_expr comma ns_name_list_body : ['$1'] ++ '$3'.
ns_name_list_body ->
  ns_name : [verify_permission_name('$1')].
ns_name_list_body ->
  regular_expr : ['$1'].

ns_name ->
  name colon name : merge_strings(['$1', '$2', '$3']).
ns_name ->
  name colon emoji : merge_strings(['$1', '$2', '$3']).
ns_name ->
  string_expr : '$1'.

regular_expr ->
  regex : ?AST("Regex"):new('$1').

value_list ->
  lbracket rbracket : ?AST("List"):new('$1', []).
value_list ->
  lbracket value_list_body rbracket : ?AST("List"):new('$1', '$2').

value_list_body ->
  value comma value_list_body : ['$1'] ++ '$3'.
value_list_body ->
  value : ['$1'].

value ->
  integer : ?AST("Integer"):new('$1').
value ->
  float : ?AST("Float"):new('$1').
value ->
  string_expr: '$1'.
value ->
  boolean: ?AST("Bool"):new('$1').
value ->
  regular_expr : '$1'.

string_expr ->
  dqstring colon string_expr : ?AST("String"):new(?AST("String"):new('$1', "\""), '$2', '$3').
string_expr ->
  sqstring colon string_expr : ?AST("String"):new(?AST("String"):new('$1', "'"), '$2', '$3').
string_expr ->
  string : ?AST("String"):new('$1').
string_expr ->
  emoji : ?AST("String"):new('$1').
string_expr ->
  name : ?AST("String"):new('$1').
string_expr ->
  dqstring : ?AST("String"):new('$1').
string_expr ->
  sqstring : ?AST("String"):new('$1').

Erlang code.

-export([parse_rule/1,
         parse_rule/2]).

-define(AST(E), (list_to_atom("Elixir.Piper.Permissions.Ast." ++ E))).

parse_rule(Text) ->
  Tracker = fun(_, _) -> ok end,
  parse_rule(Text, Tracker).

parse_rule(Text, Tracker) ->
  store_tracker(Tracker),
  case piper_rule_lexer:tokenize(Text) of
    {ok, Tokens} ->
      case parse(Tokens) of
        {ok, Ast} ->
          {ok, Ast};
        Error ->
          pp_error(Error)
      end;
    {error, {_, _, Error}, _} ->
      Message = list_to_binary([piper_rule_lexer:format_error(Error), "."]),
      {error, Message}
  end.

pp_error({error, {_, _, ["syntax error before: ", []]}}) ->
  {error, <<"Unexpected end of input.">>};
pp_error({error, {Line, _, Message}}) when is_integer(Line) ->
  {error, list_to_binary(Message)};
pp_error({error, {{Line, Col}, _, Message}}) ->
  {error, list_to_binary(io_lib:format("(Line: ~p, Col: ~p) ~s.", [Line, Col, Message]))}.

verify_command_name(String) ->
  case verify_name(String) of
    true ->
      String;
    false ->
      return_error(get_location(String), "References to commands must include bundle and command name")
  end.

verify_permission_name(String) ->
  case verify_name(String) of
    true ->
      String;
    false ->
      return_error(get_location(String), "References to permissions must start with a command bundle name or \"site\"")
  end.

verify_name(String) ->
  Value = maps:get(value, String),
  case binary:matches(Value, <<":">>) of
    [] ->
      false;
    _ ->
      true
  end.

build_arg(Arg, Type) ->
  case verify_arg(Arg, Type) of
    true ->
      ?AST("Arg"):new(Arg, Type);
    false ->
      return_error(get_location(Arg), "Only integer, \"all\", or \"any\" argument index references allowed")
  end.

store_tracker(Tracker) ->
  erlang:put(parser_tracker_ref, Tracker).

track(#{'__struct__' := 'Elixir.Piper.Permissions.Ast.Option'}=Expr) ->
  add_option(Expr);
track(#{'__struct__' := 'Elixir.Piper.Permissions.Ast.Arg'}=Expr) ->
  add_arg(Expr);
track(#{'__struct__' := 'Elixir.Piper.Permissions.Ast.List'}=Expr) ->
  track(maps:get(values, Expr)),
  Expr;
track([]) ->
  ok;
track([#{'__struct__' := 'Elixir.Piper.Permissions.Ast.String'}=Expr|T]) ->
  add_permission(Expr),
  track(T);
track([_|T]) ->
  track(T).

add_permission(Perm) ->
  Name = maps:get(value, Perm),
  Tracker = erlang:get(parser_tracker_ref),
  Tracker(permission, Name),
  Perm.

add_option(Option) ->
  Name = maps:get(name, Option),
  Tracker = erlang:get(parser_tracker_ref),
  Tracker(option, Name),
  Option.

add_arg(Arg) ->
  Index = maps:get(index, Arg),
  Tracker = erlang:get(parser_tracker_ref),
  Tracker(arg, Index),
  Arg.

verify_arg({arg, _, Index}, indexed) when Index > -1 ->
  true;
verify_arg(_, indexed) ->
  false;
verify_arg({arg, _, nil}, Index) when Index == any orelse Index == all ->
  true;
verify_arg(_, any) ->
  false.

update(#{'__struct__' := StructMod}=Expr, Opts) ->
  StructMod:update(Expr, Opts).

get_location({_, Position, _}) ->
  Position;
get_location(Token) ->
  {maps:get(line, Token), maps:get(col, Token)}.

merge_strings([{_, Pos, _}|_]=Tokens) ->
  Values = [Text || {_, _, Text} <- Tokens],
  ?AST("String"):new({string, Pos, lists:flatten(Values)}).
