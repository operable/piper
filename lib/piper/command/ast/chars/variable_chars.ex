defimpl String.Chars, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Ast.Variable

  def to_string(%Variable{value: nil, ops: ops}=var) do
    text = prefix(var)
    updated = if Enum.empty?(ops) do
      text
    else
      text <> ops_to_text(ops)
    end
    suffix(var, updated)
  end
  def to_string(%Variable{value: value}) when is_map(value) or is_list(value) do
    Poison.encode!(value)
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

  defp prefix(%Variable{name: name, prefix: prefix}) do
    "#{prefix}#{name}"
  end

  defp suffix(%Variable{suffix: nil}, text), do: text
  defp suffix(%Variable{suffix: suffix}, text), do: "#{text}#{suffix}"

end
