defimpl Piper.Permissions.Json, for: [Piper.Permissions.Ast.BinaryExpr,
                                      Piper.Permissions.Ast.ConditionalExpr] do

  alias Piper.Permissions.Ast.Json.Util

  def from_json!(svalue, %{"line" => line,
                           "col" => col,
                           "left" => left,
                           "right" => right,
                           "parens" => parens,
                           "op" => op}) do
    left = Piper.Permissions.Json.from_json!(Util.map_to_empty_struct(left), left)
    right = Piper.Permissions.Json.from_json!(Util.map_to_empty_struct(right), right)
    %{svalue | line: line, col: col, op: String.to_existing_atom(op),
      left: left, right: right, parens: parens}
  end

end
