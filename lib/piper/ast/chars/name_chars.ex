defimpl String.Chars, for: Piper.Ast.Name do
  alias Piper.Ast.Name

  def to_string(%Name{name: name}) do
    "#{name}"
  end
end
