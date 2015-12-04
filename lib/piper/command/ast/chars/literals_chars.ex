defimpl String.Chars, for: [Piper.Command.Ast.Integer,
                            Piper.Command.Ast.Float,
                            Piper.Command.Ast.Bool] do

  def to_string(literal) do
    value = Map.fetch!(literal, :value)
    "#{value}"
  end

end

defimpl String.Chars, for: [Piper.Command.Ast.String] do

  alias Piper.Command.Ast

  def to_string(%Ast.String{value: value}) do
    value
  end

end

defimpl String.Chars, for: [Piper.Command.Ast.Json] do

  alias Piper.Command.Ast

  def to_string(%Ast.Json{raw: raw}) do
    raw
  end

end

defimpl String.Chars, for: [Elixir.Map] do

  def to_string(data) do
    json = Poison.encode!(data)
    "{{" <> json <> "}}"
  end

end
