-module(piper_rule_parser).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("lib/piper/permissions/piper_rule_parser.yrl", 186).

-export([parse_rule/1]).

-define(AST(E), (list_to_atom("Elixir.Piper.Permissions.Ast." ++ E))).

parse_rule(Text) ->
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

-file("/opt/erl/r17b05/lib/erlang/lib/parsetools-2.0.12/include/yeccpre.hrl", 0).
%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 1996-2013. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The parser generator will insert appropriate declarations before this line.%

-type yecc_ret() :: {'error', _} | {'ok', _}.

-spec parse(Tokens :: list()) -> yecc_ret().
parse(Tokens) ->
    yeccpars0(Tokens, {no_func, no_line}, 0, [], []).

-spec parse_and_scan({function() | {atom(), atom()}, [_]}
                     | {atom(), atom(), [_]}) -> yecc_ret().
parse_and_scan({F, A}) ->
    yeccpars0([], {{F, A}, no_line}, 0, [], []);
parse_and_scan({M, F, A}) ->
    Arity = length(A),
    yeccpars0([], {{fun M:F/Arity, A}, no_line}, 0, [], []).

-spec format_error(any()) -> [char() | list()].
format_error(Message) ->
    case io_lib:deep_char_list(Message) of
        true ->
            Message;
        _ ->
            io_lib:write(Message)
    end.

%% To be used in grammar files to throw an error message to the parser
%% toplevel. Doesn't have to be exported!
-compile({nowarn_unused_function, return_error/2}).
-spec return_error(integer(), any()) -> no_return().
return_error(Line, Message) ->
    throw({error, {Line, ?MODULE, Message}}).

-define(CODE_VERSION, "1.4").

yeccpars0(Tokens, Tzr, State, States, Vstack) ->
    try yeccpars1(Tokens, Tzr, State, States, Vstack)
    catch 
        error: Error ->
            Stacktrace = erlang:get_stacktrace(),
            try yecc_error_type(Error, Stacktrace) of
                Desc ->
                    erlang:raise(error, {yecc_bug, ?CODE_VERSION, Desc},
                                 Stacktrace)
            catch _:_ -> erlang:raise(error, Error, Stacktrace)
            end;
        %% Probably thrown from return_error/2:
        throw: {error, {_Line, ?MODULE, _M}} = Error ->
            Error
    end.

yecc_error_type(function_clause, [{?MODULE,F,ArityOrArgs,_} | _]) ->
    case atom_to_list(F) of
        "yeccgoto_" ++ SymbolL ->
            {ok,[{atom,_,Symbol}],_} = erl_scan:string(SymbolL),
            State = case ArityOrArgs of
                        [S,_,_,_,_,_,_] -> S;
                        _ -> state_is_unknown
                    end,
            {Symbol, State, missing_in_goto_table}
    end.

yeccpars1([Token | Tokens], Tzr, State, States, Vstack) ->
    yeccpars2(State, element(1, Token), States, Vstack, Token, Tokens, Tzr);
yeccpars1([], {{F, A},_Line}, State, States, Vstack) ->
    case apply(F, A) of
        {ok, Tokens, Endline} ->
            yeccpars1(Tokens, {{F, A}, Endline}, State, States, Vstack);
        {eof, Endline} ->
            yeccpars1([], {no_func, Endline}, State, States, Vstack);
        {error, Descriptor, _Endline} ->
            {error, Descriptor}
    end;
yeccpars1([], {no_func, no_line}, State, States, Vstack) ->
    Line = 999999,
    yeccpars2(State, '$end', States, Vstack, yecc_end(Line), [],
              {no_func, Line});
yeccpars1([], {no_func, Endline}, State, States, Vstack) ->
    yeccpars2(State, '$end', States, Vstack, yecc_end(Endline), [],
              {no_func, Endline}).

%% yeccpars1/7 is called from generated code.
%%
%% When using the {includefile, Includefile} option, make sure that
%% yeccpars1/7 can be found by parsing the file without following
%% include directives. yecc will otherwise assume that an old
%% yeccpre.hrl is included (one which defines yeccpars1/5).
yeccpars1(State1, State, States, Vstack, Token0, [Token | Tokens], Tzr) ->
    yeccpars2(State, element(1, Token), [State1 | States],
              [Token0 | Vstack], Token, Tokens, Tzr);
yeccpars1(State1, State, States, Vstack, Token0, [], {{_F,_A}, _Line}=Tzr) ->
    yeccpars1([], Tzr, State, [State1 | States], [Token0 | Vstack]);
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, no_line}) ->
    Line = yecctoken_end_location(Token0),
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line});
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, Line}) ->
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line}).

%% For internal use only.
yecc_end({Line,_Column}) ->
    {'$end', Line};
yecc_end(Line) ->
    {'$end', Line}.

yecctoken_end_location(Token) ->
    try
        {text, Str} = erl_scan:token_info(Token, text),
        {line, Line} = erl_scan:token_info(Token, line),
        Parts = re:split(Str, "\n"),
        Dline = length(Parts) - 1,
        Yline = Line + Dline,
        case erl_scan:token_info(Token, column) of
            {column, Column} ->
                Col = byte_size(lists:last(Parts)),
                {Yline, Col + if Dline =:= 0 -> Column; true -> 1 end};
            undefined ->
                Yline
        end
    catch _:_ ->
        yecctoken_location(Token)
    end.

-compile({nowarn_unused_function, yeccerror/1}).
yeccerror(Token) ->
    Text = yecctoken_to_string(Token),
    Location = yecctoken_location(Token),
    {error, {Location, ?MODULE, ["syntax error before: ", Text]}}.

-compile({nowarn_unused_function, yecctoken_to_string/1}).
yecctoken_to_string(Token) ->
    case catch erl_scan:token_info(Token, text) of
        {text, Txt} -> Txt;
        _ -> yecctoken2string(Token)
    end.

yecctoken_location(Token) ->
    case catch erl_scan:token_info(Token, location) of
        {location, Loc} -> Loc;
        _ -> element(2, Token)
    end.

-compile({nowarn_unused_function, yecctoken2string/1}).
yecctoken2string({atom, _, A}) -> io_lib:write(A);
yecctoken2string({integer,_,N}) -> io_lib:write(N);
yecctoken2string({float,_,F}) -> io_lib:write(F);
yecctoken2string({char,_,C}) -> io_lib:write_char(C);
yecctoken2string({var,_,V}) -> io_lib:format("~s", [V]);
yecctoken2string({string,_,S}) -> io_lib:write_string(S);
yecctoken2string({reserved_symbol, _, A}) -> io_lib:write(A);
yecctoken2string({_Cat, _, Val}) -> io_lib:format("~p",[Val]);
yecctoken2string({dot, _}) -> "'.'";
yecctoken2string({'$end', _}) ->
    [];
yecctoken2string({Other, _}) when is_atom(Other) ->
    io_lib:write(Other);
yecctoken2string(Other) ->
    io_lib:write(Other).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



-file("lib/piper/permissions/piper_rule_parser.erl", 231).

yeccpars2(0=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(1=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_1(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(2=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_2(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(3=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(4=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(5=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_5(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(6=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(7=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_7(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(8=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_8(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(9=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(10=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(11=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(12=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(13=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(14=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(15=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(16=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_16(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(17=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(18=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(19=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(20=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_20(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(21=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_21(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(22=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_22(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(23=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_23(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(24=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_24(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(25=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_25(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(26=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_26(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(27=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_27(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(28=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(29=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(30=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(31=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(32=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(33=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_33(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(34=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_34(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(35=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_35(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(36=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(37=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(38=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(39=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_39(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(40=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_40(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(41=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_41(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(42=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_42(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(43=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_43(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(44=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_44(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(45=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_45(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(46=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_46(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(47=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_47(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(48=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_48(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(49=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_49(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(50=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_50(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(51=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(52=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_52(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(53=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(54=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_54(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(55=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(56=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_56(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(57=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_45(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_69(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_75(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_76(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_77(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_78(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_86(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, 'when', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_1(S, must, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_1_(Stack),
 yeccgoto_access_rule(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_2(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_2(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_3(S, command, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 4, Ss, Stack, T, Ts, Tzr);
yeccpars2_3(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_4(S, is, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 6, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_5(S, with, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_5_(Stack),
 yeccgoto_command_selector(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_6(S, regex, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_7_(Stack),
 yeccgoto_command_criteria(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_8_(Stack),
 yeccgoto_command_criteria(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_9(S, colon, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_9_(Stack),
 yeccgoto_string_expr(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_10_(Stack),
 yeccgoto_regular_expr(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_11(S, colon, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_11_(Stack),
 yeccgoto_string_expr(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_12(S, colon, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_12_(Stack),
 yeccgoto_string_expr(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_13(S, dqstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_13(S, sqstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_13(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_13(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_14_(Stack),
 yeccgoto_string_expr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_15: see yeccpars2_13

yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_16_(Stack),
 yeccgoto_string_expr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_17: see yeccpars2_13

yeccpars2_18(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_18_(Stack),
 yeccgoto_string_expr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_19(S, all, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(S, arg, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(S, lparen, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(S, 'not', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(S, option, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_arg_or_option(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_21_(Stack),
 yeccgoto_command_selector(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_22(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_22(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_input_criterion(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_arg_or_option(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_24(S, equiv, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, gt, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, gte, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, in, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, lt, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, lte, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, not_equiv, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_25(S, arg, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_25(S, option, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_25(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_26(S, arg, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_26(S, option, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_26(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_27_(Stack),
 yeccgoto_arg_ref(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_28: see yeccpars2_19

%% yeccpars2_29: see yeccpars2_19

yeccpars2_30(S, lbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_30(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_31(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_31(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_32(S, rbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_33_(Stack),
 yeccgoto_option_ref(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_34_(Stack),
 yeccgoto_input_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_35(S, rparen, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_35(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_36(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_36(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_36_(Stack),
 yeccgoto_input_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_37: see yeccpars2_19

%% yeccpars2_38: see yeccpars2_19

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_39_(Stack),
 yeccgoto_input_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_40_(Stack),
 yeccgoto_input_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_41_(Stack),
 yeccgoto_arg_ref(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_42_(Stack),
 yeccgoto_option_ref(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_43_(Stack),
 yeccgoto_arg_ref(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_44_(Stack),
 yeccgoto_option_ref(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_45(S, boolean, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(S, regex, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_46_(Stack),
 yeccgoto_input_criteria_binop(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_47_(Stack),
 yeccgoto_input_criteria_binop(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_48_(Stack),
 yeccgoto_input_criteria_binop(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_49(S, lbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_49(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_50_(Stack),
 yeccgoto_input_criteria_binop(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_51_(Stack),
 yeccgoto_input_criteria_binop(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_52_(Stack),
 yeccgoto_input_criteria_binop(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_53_(Stack),
 yeccgoto_input_criteria(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_54(S, boolean, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_54(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_54(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_54(S, rbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_54(S, regex, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_54(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_55(S, rbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_56(S, comma, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_56_(Stack),
 yeccgoto_value_list_body(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_value(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_value(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_59_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_60_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_61_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_62_(Stack),
 yeccgoto_value_list(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_63: see yeccpars2_45

yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_64_(Stack),
 yeccgoto_value_list_body(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_65_(Stack),
 yeccgoto_value_list(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_66_(Stack),
 yeccgoto_input_criteria(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_67: see yeccpars2_19

%% yeccpars2_68: see yeccpars2_19

yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_69_(Stack),
 yeccgoto_input_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_70_(Stack),
 yeccgoto_input_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_71_(Stack),
 yeccgoto_access_rule(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_72(S, have, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_72(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_73(S, all, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_73(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_73(S, lparen, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_73(S, 'not', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_74_(Stack),
 yeccgoto_permission_criteria(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_75(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_75_(Stack),
 yeccgoto_permission_selector(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_76(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_permission_criterion(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_77(S, in, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_77(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_78(S, in, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_78(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_79: see yeccpars2_73

%% yeccpars2_80: see yeccpars2_73

yeccpars2_81(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_81_(Stack),
 yeccgoto_permission_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_82(S, rparen, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_82(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_83(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_83_(Stack),
 yeccgoto_permission_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_84: see yeccpars2_73

%% yeccpars2_85: see yeccpars2_73

yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_86_(Stack),
 yeccgoto_permission_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_87_(Stack),
 yeccgoto_permission_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_88(S, lbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_88(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_89_(Stack),
 yeccgoto_permission_criteria(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_90(S, rbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(S, regex, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_91(S, comma, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_91_(Stack),
 yeccgoto_ns_name_list_body(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_92(S, comma, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_92_(Stack),
 yeccgoto_ns_name_list_body(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_93(S, rbracket, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_94_(Stack),
 yeccgoto_ns_name_list(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_95_(Stack),
 yeccgoto_ns_name_list(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_96: see yeccpars2_6

yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_97_(Stack),
 yeccgoto_ns_name_list_body(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_98: see yeccpars2_6

yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_99_(Stack),
 yeccgoto_ns_name_list_body(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_100: see yeccpars2_88

yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_101_(Stack),
 yeccgoto_permission_criteria(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_102: see yeccpars2_73

%% yeccpars2_103: see yeccpars2_73

yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_104_(Stack),
 yeccgoto_permission_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_105_(Stack),
 yeccgoto_permission_criterion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccgoto_access_rule(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_arg_or_option(19, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_or_option(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_or_option(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_or_option(37, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_or_option(38, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_or_option(67, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_or_option(68, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(24, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_arg_ref(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_ref(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_ref(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_ref(37=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_ref(38=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_ref(67=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_arg_ref(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_command_criteria(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_command_selector(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_input_criteria(19, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criteria(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criteria(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criteria(37, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criteria(38, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criteria(67, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criteria(68, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(22, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_input_criteria_binop(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_45(45, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_input_criterion(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criterion(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(35, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criterion(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criterion(37=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criterion(38=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criterion(67=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_input_criterion(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ns_name_list(88=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ns_name_list(100=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ns_name_list_body(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(93, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ns_name_list_body(96=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ns_name_list_body(98=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_option_ref(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_option_ref(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_option_ref(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_option_ref(37=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_option_ref(38=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_option_ref(67=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_option_ref(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_permission_criteria(73, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criteria(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criteria(80, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criteria(84, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criteria(85, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criteria(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criteria(103, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_permission_criterion(73=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_75(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criterion(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(82, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criterion(80=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criterion(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criterion(85=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criterion(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_permission_criterion(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_permission_selector(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_regular_expr(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_regular_expr(45=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_regular_expr(54=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_regular_expr(63=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_regular_expr(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(92, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_regular_expr(96, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(92, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_regular_expr(98, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(92, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_string_expr(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(13=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(17=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(45=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(54=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(63=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(73=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(80=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(85=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(96, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(98, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_string_expr(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value(45=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(54, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(63, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value_list(49=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value_list_body(54, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(55, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value_list_body(63=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr).

-file("lib/piper/permissions/piper_rule_parser.erl", 1174).
-compile({inline,yeccpars2_1_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 30).
yeccpars2_1_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Rule" ) : new ( __1 , nil )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1183).
-compile({inline,yeccpars2_5_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 35).
yeccpars2_5_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   update ( __3 , [ { left , ? AST ( "Var" ) : new ( << "command" >> ) } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1192).
-compile({inline,yeccpars2_7_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 73).
yeccpars2_7_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 , [ { right , verify_name ( __2 ) } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1201).
-compile({inline,yeccpars2_8_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 75).
yeccpars2_8_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 , [ { right , __2 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1210).
-compile({inline,yeccpars2_9_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 178).
yeccpars2_9_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "String" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1219).
-compile({inline,yeccpars2_10_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 146).
yeccpars2_10_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Regex" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1228).
-compile({inline,yeccpars2_11_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 180).
yeccpars2_11_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "String" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1237).
-compile({inline,yeccpars2_12_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 176).
yeccpars2_12_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "String" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1246).
-compile({inline,yeccpars2_14_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 170).
yeccpars2_14_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "String" ) : new ( ? AST ( "String" ) : new ( __1 ) , __2 , __3 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1255).
-compile({inline,yeccpars2_16_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 174).
yeccpars2_16_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "String" ) : new ( ? AST ( "String" ) : new ( __1 , "'" ) , __2 , __3 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1264).
-compile({inline,yeccpars2_18_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 172).
yeccpars2_18_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "String" ) : new ( ? AST ( "String" ) : new ( __1 , "\"" ) , __2 , __3 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1273).
-compile({inline,yeccpars2_21_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 37).
yeccpars2_21_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Lhs = update ( __3 , [ { left , ? AST ( "Var" ) : new ( << "command" >> ) } ] ) ,
    ? AST ( "BinaryExpr" ) : new ( __4 , [ { left , Lhs } ,
    { right , __5 } ] )
  end | __Stack].

-compile({inline,yeccpars2_27_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 116).
yeccpars2_27_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_arg ( __1 , indexed )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1292).
-compile({inline,yeccpars2_33_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 109).
yeccpars2_33_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Option" ) : new ( __1 , __3 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1301).
-compile({inline,yeccpars2_34_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 80).
yeccpars2_34_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "UnaryExpr" ) : new ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_36_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 82).
yeccpars2_36_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   update ( __2 , [ { parens , true } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1318).
-compile({inline,yeccpars2_39_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 87).
yeccpars2_39_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Lhs = update ( __2 , [ { parens , true } ] ) ,
    ? AST ( "ConditionalExpr" ) : new ( __4 , [ { left , Lhs } , { right , __5 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1328).
-compile({inline,yeccpars2_40_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 84).
yeccpars2_40_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Lhs = update ( __2 , [ { parens , true } ] ) ,
    ? AST ( "ConditionalExpr" ) : new ( __4 , [ { left , Lhs } , { right , __5 } ] )
  end | __Stack].

-compile({inline,yeccpars2_41_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 112).
yeccpars2_41_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_arg ( __2 , any )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1346).
-compile({inline,yeccpars2_42_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 105).
yeccpars2_42_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Option" ) : new ( __2 , any )
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 114).
yeccpars2_43_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_arg ( __2 , all )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1363).
-compile({inline,yeccpars2_44_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 107).
yeccpars2_44_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Option" ) : new ( __2 , all )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1372).
-compile({inline,yeccpars2_46_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 119).
yeccpars2_46_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1381).
-compile({inline,yeccpars2_47_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 123).
yeccpars2_47_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1390).
-compile({inline,yeccpars2_48_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 127).
yeccpars2_48_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1399).
-compile({inline,yeccpars2_50_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 125).
yeccpars2_50_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1408).
-compile({inline,yeccpars2_51_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 129).
yeccpars2_51_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1417).
-compile({inline,yeccpars2_52_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 121).
yeccpars2_52_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "BinaryExpr" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1426).
-compile({inline,yeccpars2_53_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 97).
yeccpars2_53_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "ContainExpr" ) : new ( __2 , __1 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 156).
yeccpars2_56_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1443).
-compile({inline,yeccpars2_59_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 165).
yeccpars2_59_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Bool" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1452).
-compile({inline,yeccpars2_60_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 161).
yeccpars2_60_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Float" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1461).
-compile({inline,yeccpars2_61_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 159).
yeccpars2_61_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Integer" ) : new ( __1 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1470).
-compile({inline,yeccpars2_62_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 149).
yeccpars2_62_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "List" ) : new ( __1 , [ ] )
  end | __Stack].

-compile({inline,yeccpars2_64_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 154).
yeccpars2_64_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 ] ++ __3
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1487).
-compile({inline,yeccpars2_65_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 151).
yeccpars2_65_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "List" ) : new ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_66_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 95).
yeccpars2_66_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   update ( __2 , [ { left , __1 } , { right , __3 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1504).
-compile({inline,yeccpars2_69_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 92).
yeccpars2_69_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "ConditionalExpr" ) : new ( __2 , [ { left , __1 } , { right , __3 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1513).
-compile({inline,yeccpars2_70_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 90).
yeccpars2_70_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "ConditionalExpr" ) : new ( __2 , [ { left , __1 } , { right , __3 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1522).
-compile({inline,yeccpars2_71_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 32).
yeccpars2_71_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "Rule" ) : new ( __1 , __2 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1531).
-compile({inline,yeccpars2_74_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 69).
yeccpars2_74_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   verify_name ( __1 ) ,
    ? AST ( "PermissionExpr" ) : new ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_75_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 41).
yeccpars2_75_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1549).
-compile({inline,yeccpars2_81_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 46).
yeccpars2_81_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "UnaryExpr" ) : new ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_83_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 48).
yeccpars2_83_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   update ( __2 , [ { parens , true } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1566).
-compile({inline,yeccpars2_86_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 54).
yeccpars2_86_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Lhs = update ( __2 , [ { parens , true } ] ) ,
    ? AST ( "ConditionalExpr" ) : new ( __4 , [ { left , Lhs } ,
    { right , __5 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1577).
-compile({inline,yeccpars2_87_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 50).
yeccpars2_87_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Lhs = update ( __2 , [ { parens , true } ] ) ,
    ? AST ( "ConditionalExpr" ) : new ( __4 , [ { left , Lhs } ,
    { right , __5 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1588).
-compile({inline,yeccpars2_89_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 65).
yeccpars2_89_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "PermissionExpr" ) : new ( __1 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_91_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 141).
yeccpars2_91_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ verify_name ( __1 ) ]
  end | __Stack].

-compile({inline,yeccpars2_92_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 143).
yeccpars2_92_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1613).
-compile({inline,yeccpars2_94_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 132).
yeccpars2_94_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "List" ) : new ( __1 , [ ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1622).
-compile({inline,yeccpars2_95_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 134).
yeccpars2_95_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "List" ) : new ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_97_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 139).
yeccpars2_97_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 ] ++ __3
  end | __Stack].

-compile({inline,yeccpars2_99_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 137).
yeccpars2_99_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ verify_name ( __1 ) ] ++ __3
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1647).
-compile({inline,yeccpars2_101_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 67).
yeccpars2_101_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "PermissionExpr" ) : new ( __1 , __3 )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1656).
-compile({inline,yeccpars2_104_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 61).
yeccpars2_104_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "ConditionalExpr" ) : new ( __2 , [ { left , __1 } ,
    { right , __3 } ] )
  end | __Stack].

-file("lib/piper/permissions/piper_rule_parser.erl", 1666).
-compile({inline,yeccpars2_105_/1}).
-file("lib/piper/permissions/piper_rule_parser.yrl", 58).
yeccpars2_105_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ? AST ( "ConditionalExpr" ) : new ( __2 , [ { left , __1 } ,
    { right , __3 } ] )
  end | __Stack].


-file("lib/piper/permissions/piper_rule_parser.yrl", 229).
