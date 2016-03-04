defimpl String.Chars, for: [Piper.Command.Ast2.Integer,
                            Piper.Command.Ast2.Float,
                            Piper.Command.Ast2.Bool] do

  def to_string(literal) do
    "#{literal.value}"
  end

end

defimpl String.Chars, for: [Piper.Command.Ast2.String] do

  def to_string(str) do
    str.value
  end

end

defimpl String.Chars, for: [Piper.Command.Ast2.Emoji] do

  def to_string(emoji) do
    emoji.value
  end

end
