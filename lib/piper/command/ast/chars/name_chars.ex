defimpl String.Chars, for: Piper.Command.Ast.Name do
  alias Piper.Command.Ast.Name

  def to_string(%Name{bundle: nil, entity: entity}) do
    "#{entity}"
  end
  def to_string(%Name{bundle: bundle, entity: entity}) do
    "#{bundle}:#{entity}"
  end
end
