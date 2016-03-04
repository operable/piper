defmodule Piper.Command.Ast2.Variable do

  defstruct [:line, :col, :name, :value]

  def new({:variable, {line, col}, name}) do
    %__MODULE__{line: line, col: col, name: name}
  end

end
