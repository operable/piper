defimpl String.Chars, for: Piper.Command.Ast2.Redirect do

  alias Piper.Command.Ast2

  def to_string(%Ast2.Redirect{type: type, targets: targets}) do
    targets = Enum.map(targets, &("#{&1}"))
    "#{symbol_for_type(type)} #{Enum.join(targets, " ")}"
  end

  defp symbol_for_type(:redir_one) do
    ">"
  end
  defp symbol_for_type(:redir_multi) do
    "*>"
  end

end
