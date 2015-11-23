defmodule Piper.Ast.Option do

  defstruct [:line, :col, :finalized, :flag, :value]

  alias Piper.Ast
  alias Piper.Util.Token

  def new(%Token{line: line, col: col, text: text, type: type}) when type in [:string, :integer] do
    %__MODULE__{line: line, col: col, flag: text}
  end
  def new(%Ast.Variable{}=var) do
    %__MODULE__{line: var.line, col: var.col, flag: var}
  end

  def set_value(%__MODULE__{}=opt, value) do
    opt = %{opt | value: value}
  end

end
