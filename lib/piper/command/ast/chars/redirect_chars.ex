defimpl String.Chars, for: Piper.Command.Ast.Redirect do

  alias Piper.Command.Ast

  def to_string(%Ast.Redirect{type: type, targets: targets}) do
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
