defimpl Piper.Permissions.Json, for: Piper.Permissions.Ast.PermissionExpr do

  def from_json!(svalue, %{"line" => line,
                           "col" => col,
                           "op" => op,
                           "perms" => perms}) do
    %{svalue | line: line, col: col, op: String.to_existing_atom(op),
      perms: Piper.Permissions.Json.from_json!(perms, perms)}
  end

end
