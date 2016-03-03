defimpl String.Chars, for: [Piper.Command.Ast2.Integer,
                            Piper.Command.Ast2.Float,
                            Piper.Command.Ast2.Bool] do

  def to_string(literal) do
    value = Map.fetch!(literal, :value)
    "#{value}"
  end

end

defimpl String.Chars, for: [Piper.Command.Ast2.String] do

  alias Piper.Command.Ast2

  def to_string(%Ast2.String{value: value}) do
    value
  end

end
