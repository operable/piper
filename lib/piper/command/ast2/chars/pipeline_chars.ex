defimpl String.Chars, for: Piper.Command.Ast2.Pipeline do

  alias Piper.Command.Ast2

  def to_string(%Ast2.Pipeline{head: head}) do
    "#{head}"
  end

end
