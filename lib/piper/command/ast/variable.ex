defmodule Piper.Command.Ast.Variable do

  defstruct [:line, :col, :name, :value, :ops, :prefix, :suffix]

  def new(var_info, ops \\ [])

  def new({:variable, {line, col}, name}, ops) do
    %__MODULE__{line: line, col: col, name: name, ops: ops, prefix: "$"}
  end

  def new(name, ops) when is_binary(name) do
    %__MODULE__{line: 0, col: 0, name: name, ops: ops, prefix: "$"}
  end

  def as_interpolated(%__MODULE__{}=var) do
    var = %{var | prefix: "${", suffix: "}"}
    "#{var}"
  end

end
