defimpl String.Chars, for: Piper.Command.Ast2.Name do
  alias Piper.Command.Ast2.Name

  def to_string(%Name{bundle: nil, entity: entity}) do
    "#{entity}"
  end
  def to_string(%Name{bundle: bundle, entity: entity}) do
    "#{bundle}:#{entity}"
  end
end
