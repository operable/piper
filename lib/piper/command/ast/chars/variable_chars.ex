defimpl String.Chars, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Ast.Variable

  def to_string(%Variable{name: name, value: nil}) do
    "$#{name}"
  end
  def to_string(%Variable{value: value}) do
    "#{value}"
  end

end
