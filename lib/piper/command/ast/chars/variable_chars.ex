defimpl String.Chars, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Ast.Variable

  def to_string(%Variable{name: name, index: nil}) do
    "$#{name}"
  end
  def to_string(%Variable{name: name, index: index}) do
    "$#{name}[#{index}]"
  end
end
