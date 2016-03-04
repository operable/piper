defimpl String.Chars, for: Piper.Command.Ast2.Variable do

  alias Piper.Command.Ast2.Variable

  def to_string(%Variable{name: name, value: nil}) do
    "$#{name}"
  end
  def to_string(%Variable{value: value}) do
    "#{value}"
  end

end
