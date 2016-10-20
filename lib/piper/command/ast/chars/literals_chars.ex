defimpl String.Chars, for: [Piper.Command.Ast.Integer,
                            Piper.Command.Ast.Float,
                            Piper.Command.Ast.Bool] do

  def to_string(literal) do
    "#{literal.value}"
  end

end

defimpl String.Chars, for: [Piper.Command.Ast.String] do

  alias Piper.Command.Ast

  def to_string(%Ast.String{quote_type: :squote, value: value}) do
    "'#{value}'"
  end
  def to_string(%Ast.String{quote_type: :dquote, value: value}) do
    "\"#{value}\""
  end
  def to_string(%Ast.String{quote_type: nil, value: value}) do
    value
  end

end

defimpl String.Chars, for: [Piper.Command.Ast.Emoji] do

  def to_string(emoji) do
    emoji.value
  end

end
