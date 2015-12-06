Terminals

%% Keywords
all any arg command have is must option when with

%% Operators
and or not in equiv not_equiv lt gt lte gte

%% Data types
boolean float integer dqstring sqstring string regex

%% Punctuation
colon comma lbracket rbracket lparen rparen.

Nonterminals

access_rule

command_selector command_criteria

ns_name_list ns_name_list_body

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
  not permission_criterion : ?AST("UnaryExpr"):new('$1', '$2').
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
  any in ns_name_list : ?AST("PermissionExpr"):new('$1', track_permissions('$3')).
permission_criteria ->
  all in ns_name_list : ?AST("PermissionExpr"):new('$1', track_permissions('$3')).
permission_criteria ->
  string_expr : verify_name('$1'),
                ?AST("PermissionExpr"):new(add_permission('$1')).

command_criteria ->
  is string_expr : ?AST("BinaryExpr"):new('$1', [{right, verify_name('$2')}]).
command_criteria ->
  is regular_expr : ?AST("BinaryExpr"):new('$1', [{right, '$2'}]).

input_criterion ->
  input_criteria : '$1'.
input_criterion ->
  not input_criterion : ?AST("UnaryExpr"):new('$1', '$2').
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
  arg_ref : '$1'.
arg_or_option ->
  option_ref : '$1'.

option_ref ->
  any option : ?AST("Option"):new('$2', any).
option_ref ->
  all option : ?AST("Option"):new('$2', all).
option_ref ->
  option lbracket string rbracket : ?AST("Option"):new('$1', '$3').

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
  string_expr comma ns_name_list_body : [verify_name('$1')] ++ '$3'.
ns_name_list_body ->
  regular_expr comma ns_name_list_body : ['$1'] ++ '$3'.
ns_name_list_body ->
  string_expr : [verify_name('$1')].
ns_name_list_body ->
  regular_expr : ['$1'].

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
  string colon string_expr : ?AST("String"):new(?AST("String"):new('$1'), '$2', '$3').
string_expr ->
  dqstring colon string_expr : ?AST("String"):new(?AST("String"):new('$1', "\""), '$2', '$3').
string_expr ->
  sqstring colon string_expr : ?AST("String"):new(?AST("String"):new('$1', "'"), '$2', '$3').
string_expr ->
  string : ?AST("String"):new('$1').
string_expr ->
  dqstring : ?AST("String"):new('$1').
string_expr ->
  sqstring : ?AST("String"):new('$1').

Erlang code.

-export([parse_rule/1, parse_rule/2]).

-define(AST(E), (list_to_atom("Elixir.Piper.Permissions.Ast." ++ E))).

parse_rule(Text) ->
  Tracker = fun(_) -> ok end,
  parse_rule(Text, Tracker).

parse_rule(Text, Tracker) ->
  store_tracker(Tracker),
  case piper_rule_lexer:tokenize(Text) of
    {ok, Tokens} ->
      parse(Tokens);
    Error ->
      Error
  end.

verify_name(String) ->
  Value = maps:get(value, String),
  case binary:matches(Value, <<":">>) of
    [] ->
      throw({error, bad_name});
    _ ->
      String
  end.

build_arg(Arg, Type) ->
  case verify_arg(Arg, Type) of
    true ->
      ?AST("Arg"):new(Arg, Type);
    false ->
      throw({error, bad_arg_ref})
  end.

store_tracker(Tracker) ->
  erlang:put(permission_tracker_ref, Tracker).

track_permissions(#{'__struct__' := 'Elixir.Piper.Permissions.Ast.List'}=Expr) ->
  track_permissions(maps:get(values, Expr)),
  Expr;
track_permissions([]) ->
  ok;
track_permissions([#{'__struct__' := 'Elixir.Piper.Permissions.Ast.String'}=Expr|T]) ->
  add_permission(Expr),
  track_permissions(T);
track_permissions([_|T]) ->
  track_permissions(T).

add_permission(Perm) ->
  Name = maps:get(value, Perm),
  Tracker = erlang:get(permission_tracker_ref),
  Tracker(Name),
  Perm.

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
