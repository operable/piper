defimpl Piper.Permissions.Json, for: Piper.Permissions.Ast.ContainExpr do

  alias Piper.Permissions.Ast.Json.Util

  def from_json!(svalue, %{"line" => line,
                           "col" => col,
                           "left" => left,
                           "right" => right,
                           "lhs_agg" => lhs_agg,
                           "parens" => parens}) do
    left = Piper.Permissions.Json.from_json!(Util.map_to_empty_struct(left), left)
    right = Piper.Permissions.Json.from_json!(Util.map_to_empty_struct(right), right)
    %{svalue | line: line, col: col, left: left, right: right, parens: parens,
      lhs_agg: parse_agg(lhs_agg)}
  end

  defp parse_agg("any"), do: :any
  defp parse_agg("all"), do: :all
  defp parse_agg(agg), do: agg

end
