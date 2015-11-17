defimpl String.Chars, for: Piper.Ast.Variable do

  alias Piper.Ast.Variable

  def to_string(%Variable{name: name, index: nil}) do
    "$#{name}"
  end
  def to_string(%Variable{name: name, index: index}) do
    "$#{name}[#{index}]"
  end
end
