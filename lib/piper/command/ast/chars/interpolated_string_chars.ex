defimpl String.Chars, for: Piper.Command.Ast.InterpolatedString do

  alias Piper.Command.Ast.Variable
  alias Piper.Command.Ast.InterpolatedString

  def to_string(%InterpolatedString{exprs: exprs, quote_type: quote_type, bound: false}) do
    text = exprs
           |> Enum.map(&(convert_element(&1)))
           |> Enum.join
    wrap_quotes(text, quote_type)
  end
  def to_string(%InterpolatedString{bound: true, exprs: exprs}) do
    Enum.map_join(exprs, &("#{&1}"))
  end

  defp convert_element(%Variable{}=element) do
    Variable.as_interpolated(element)
  end
  defp convert_element(element), do: "#{element}"

  defp wrap_quotes(text, nil), do: text
  defp wrap_quotes(text, :squote), do: "'#{text}'"
  defp wrap_quotes(text, :dquote), do: "\"#{text}\""

end
