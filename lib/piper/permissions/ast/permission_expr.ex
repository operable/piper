defmodule Piper.Permissions.Ast.PermissionExpr do

  alias Piper.Permissions.Ast

  defstruct [:line, :col, :op, :perms]

  def new({op, {line, col}, _}, perms) when op in [:all, :any] do
    %__MODULE__{line: line, col: col, op: op, perms: perms}
  end

  def new(%Ast.String{}=perm) do
    %__MODULE__{line: perm.line, col: perm.col, op: :has, perms: perm}
  end

end
