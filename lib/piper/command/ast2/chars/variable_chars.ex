defimpl String.Chars, for: Piper.Command.Ast2.Variable do

  alias Piper.Command.Ast2.Variable

  def to_string(%Variable{name: name}) do
    "$#{name}"
  end

end
