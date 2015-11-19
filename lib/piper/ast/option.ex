defmodule Piper.Ast.Option do

  defstruct [:line, :col, :finalized, :flag, :value]

  alias Piper.Ast
  alias Piper.Util.Token

  def new(%Token{line: line, col: col, text: text, type: :option}) do
    %__MODULE__{line: line, col: col, flag: text}
  end
  def new(%Token{line: line, col: col, type: :optvar}=token) do
    var = Ast.Variable.new(token)
    %__MODULE__{line: line, col: col, flag: var}
  end


  def set_value(%__MODULE__{}=opt, value) do
    %{opt | value: value}
  end

end
