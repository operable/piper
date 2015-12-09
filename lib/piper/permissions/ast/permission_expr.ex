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

  def build(op, perms) when is_list(perms) and op in [:all, :any] do
    perms = for perm <- perms do
      %Ast.String{value: perm}
    end
    perm_list = %Ast.List{values: perms}
    %__MODULE__{op: op, perms: perm_list}
  end

  def build(perm) when is_binary(perm) do
    %__MODULE__{op: :has, perms: %Ast.String{value: perm}}
  end

end
