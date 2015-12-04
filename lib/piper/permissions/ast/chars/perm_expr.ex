defimpl String.Chars, for: Piper.Permissions.Ast.PermissionExpr do

  alias Piper.Permissions.Ast

  def to_string(%Ast.PermissionExpr{op: :has, perms: perms}) do
    "#{perms}"
  end
  def to_string(%Ast.PermissionExpr{op: op, perms: perms}) when op in [:any, :all] do
    "#{op} in #{perms}"
  end
end
