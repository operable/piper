defmodule Piper.Command.Ast.Invocation do

  alias Piper.Util.Token
  alias Piper.Command.Ast

  defstruct [line: nil, col: nil, command: nil, args: [], options: []]

  def new(%Token{type: :string}=token) do
    %__MODULE__{line: token.line, col: token.col,
                command: token.text}
  end
  def new(%Ast.Variable{line: line, col: col}=var) do
    %__MODULE__{line: line, col: col, command: var}
  end
  def add_arg(%__MODULE__{args: args}=invocation, arg) do
    %{invocation | args: args ++ [arg]}
  end

end
