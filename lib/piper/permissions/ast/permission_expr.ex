defmodule Piper.Permissions.Ast.PermissionExpr do

  @derive [Poison.Encoder]

  alias Piper.Permissions.Ast

  defstruct [{:'$ast$', "perm_expr"}, :line, :col, :op, :perms]

  def new({op, {line, col}, _}, perms) when op in [:all, :any] do
    %__MODULE__{line: line, col: col, op: op, perms: perms}
  end

  def new(%Ast.String{}=perm) do
    %__MODULE__{line: perm.line, col: perm.col, op: :has, perms: perm}
  end

end
