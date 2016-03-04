defimpl String.Chars, for: Piper.Command.Ast2.Invocation do

  alias Piper.Command.Ast2

  def to_string(%Ast2.Invocation{name: name, args: args, redir: redir}) do
    formatted_args = if Enum.empty?(args) do
      ""
    else
      " " <> Enum.join(Enum.map(args, &("#{&1}")), " ")
    end
    formatted_command = "#{name}#{formatted_args}"
    if redir == nil do
      formatted_command
    else
      formatted_command <> " #{redir}"
    end
  end

end

defimpl String.Chars, for: Piper.Command.Ast2.InvocationConnector do

  alias Piper.Command.Ast2

  def to_string(%Ast2.InvocationConnector{type: type, left: left, right: right}) do
    left = String.strip("#{left}")
    right = String.strip("#{right}")
    left <> " #{symbol_for_type(type)} " <> right
  end

  defp symbol_for_type(:iff) do
    "&&"
  end
  defp symbol_for_type(:pipe) do
    "|"
  end

end
