defimpl String.Chars, for: [Piper.Command.Ast.Integer,
                            Piper.Command.Ast.Float,
                            Piper.Command.Ast.Bool] do

  def to_string(literal) do
    "#{literal.value}"
  end

end

defimpl String.Chars, for: [Piper.Command.Ast.String] do

  def to_string(str) do
    str.value
  end

end

defimpl String.Chars, for: [Piper.Command.Ast.Emoji] do

  def to_string(emoji) do
    emoji.value
  end

end
