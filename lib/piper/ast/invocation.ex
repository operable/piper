defmodule Piper.Ast.Invocation do

  defstruct [line: nil, col: nil, command: nil, args: [], options: []]

  alias Piper.Util.Token
  alias Piper.Ast

  def new(%Token{type: :name}=token) do
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
