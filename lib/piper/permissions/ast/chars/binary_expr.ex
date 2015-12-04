defimpl String.Chars, for: Piper.Permissions.Ast.BinaryExpr do

  alias Piper.Permissions.Ast

  def to_string(%Ast.BinaryExpr{left: left, right: right, op: op,
                                parens: parens}) do
    text = "#{translate(left)} #{translate(op)} #{translate(right)}"
    if parens == true do
      "(" <> text <> ")"
    else
      text
    end
  end

  defp translate(:gt), do: ">"
  defp translate(:lt), do: "<"
  defp translate(:gte), do: ">="
  defp translate(:lte), do: "=<"
  defp translate(:equiv), do: "=="
  defp translate(:matches), do: "=="
  defp translate(:not_equiv), do: "!="
  defp translate(:not_matches), do: "!="
  defp translate(:in), do: "in"
  defp translate(:is), do: "is"
  defp translate(:and), do: "and"
  defp translate(:or), do: "or"
  defp translate(:with), do: "with"
  defp translate(data) when is_list(data) do
    "[" <> Enum.join((for d <- data, do: "#{d}"), ", ") <> "]"
  end
  defp translate(term) do
    "#{term}"
  end
end
