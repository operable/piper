defimpl String.Chars, for: [Piper.Ast.Integer,
                            Piper.Ast.Float] do

  def to_string(literal) do
    value = Map.fetch!(literal, :value)
    "#{value}"
  end

end

defimpl String.Chars, for: [Piper.Ast.String] do

  alias Piper.Ast

  def to_string(%Ast.String{raw: raw, value: value}) do
    if raw == nil do
      value
    else
      raw
    end
  end

end
