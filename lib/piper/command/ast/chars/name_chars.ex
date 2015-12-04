defimpl String.Chars, for: Piper.Command.Ast.Name do
  alias Piper.Command.Ast.Name

  def to_string(%Name{name: name}) do
    "#{name}"
  end
end
