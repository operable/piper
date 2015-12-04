defmodule Piper.Permissions.Ast.UnaryExpr do

  defstruct [:line, :col, :op, :expr]

  def new({op, {line, col}, _}, expr) do
    %__MODULE__{line: line, col: col, op: op, expr: expr}
  end

end
