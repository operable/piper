defmodule Piper.Command.Ast.Variable do

  alias Piper.Command.Ast.Util

  defstruct [:line, :col, :name, :value, :ops]

  def new({:variable, meta, name}, ops \\ []) do
    name = String.slice(String.Chars.to_string(name), 1, length(name))
    {line, col} = Util.position(meta)
    %__MODULE__{line: line, col: col, name: name, ops: ops}
  end

end
