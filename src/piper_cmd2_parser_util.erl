-module(piper_cmd2_parser_util).

-export([parse_token/3,
         parse_token/4,
         new_ast/2]).

parse_token(Token, Name, Handler) ->
  parse_token(Token, Name, Name, Handler).

parse_token({_, {Line, _} = Position, Value}, Lexer, Parser, Handler) ->
  Context = erlang:get(piper_cp_context),
  Old = 'Elixir.Piper.Command.ParseContext':position(Context),
  'Elixir.Piper.Command.ParseContext':set_position(Context, Position),
  LexerMod = lexer_for_name(Lexer),
  ParserMod = parser_for_name(Parser),
  try
    case LexerMod:string(Value) of
      {ok, Tokens, _} ->
        case ParserMod:parse(Tokens) of
          {ok, Results} ->
            Handler(Results);
          Error ->
            ParserMod:return_error(Line, Error)
        end;
      {error, {_, _, Error}, _} ->
        ParserMod:return_error(Line, LexerMod:format_error(Error))
    end
  after
    'Elixir.Piper.Command.ParseContext':set_position(Context, Old)
  end.

new_ast(Name, Args) ->
  apply(ast_node_for_name(Name), new, Args).

lexer_for_name(name) ->
  piper_cmd2_name_lexer;
lexer_for_name(arg) ->
  piper_cmd2_arg_lexer;
lexer_for_name(var) ->
  piper_cmd2_var_lexer;
lexer_for_name(interp) ->
  piper_cmd2_interp_lexer.

parser_for_name(name) ->
  piper_cmd2_name_parser;
parser_for_name(arg) ->
  piper_cmd2_arg_parser;
parser_for_name(var) ->
  piper_cmd2_var_parser;
parser_for_name(interp) ->
  piper_cmd2_interp_parser.

ast_node_for_name(integer) ->
  'Elixir.Piper.Command.Ast.Integer';
ast_node_for_name(float) ->
  'Elixir.Piper.Command.Ast.Float';
ast_node_for_name(bool) ->
  'Elixir.Piper.Command.Ast.Bool';
ast_node_for_name(string) ->
  'Elixir.Piper.Command.Ast.String';
ast_node_for_name(option) ->
  'Elixir.Piper.Command.Ast.Option';
ast_node_for_name(name) ->
  'Elixir.Piper.Command.Ast.Name';
ast_node_for_name(invocation) ->
  'Elixir.Piper.Command.Ast.Invocation';
ast_node_for_name(pipeline_stage) ->
  'Elixir.Piper.Command.Ast.PipelineStage';
ast_node_for_name(pipeline) ->
  'Elixir.Piper.Command.Ast.Pipeline';
ast_node_for_name(redirect) ->
  'Elixir.Piper.Command.Ast.Redirect';
ast_node_for_name(variable) ->
  'Elixir.Piper.Command.Ast.Variable';
ast_node_for_name(interp_string) ->
  'Elixir.Piper.Command.Ast.InterpolatedString'.
