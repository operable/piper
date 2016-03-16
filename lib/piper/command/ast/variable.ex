defmodule Piper.Command.Ast.Variable do

  defstruct [:line, :col, :name, :value, :ops]

  def new({:variable, {line, col}, name}, ops \\ []) do
    %__MODULE__{line: line, col: col, name: name, ops: ops}
  end

end
