defimpl String.Chars, for: [Piper.Ast.Integer,
                            Piper.Ast.Float,
                            Piper.Ast.Bool] do

  def to_string(literal) do
    value = Map.fetch!(literal, :value)
    "#{value}"
  end

end

defimpl String.Chars, for: [Piper.Ast.String] do

  alias Piper.Ast

  def to_string(%Ast.String{value: value}) do
    value
  end

end

defimpl String.Chars, for: [Piper.Ast.Json] do

  alias Piper.Ast

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
