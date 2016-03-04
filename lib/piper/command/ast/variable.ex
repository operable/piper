defmodule Piper.Command.Ast.Variable do

  defstruct [:line, :col, :name, :value]

  def new({:variable, {line, col}, name}) do
    %__MODULE__{line: line, col: col, name: name}
  end

end
