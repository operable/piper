defimpl String.Chars, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Ast.Variable

  def to_string(%Variable{name: name, value: nil, ops: ops}) do
    text = "$#{name}"
    if Enum.empty?(ops) do
      text
    else
      text <> ops_to_text(ops)
    end
  end
  def to_string(%Variable{value: value}) do
    "#{value}"
  end

  defp ops_to_text(ops) do
    Enum.reduce(ops, "", &op_to_text/2)
  end

  defp op_to_text({:index, index}, acc) do
    acc <> "[#{index}]"
  end
  defp op_to_text({:key, key}, acc) do
    acc <> ".#{key}"
  end

end
