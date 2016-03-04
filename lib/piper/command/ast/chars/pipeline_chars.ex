defimpl String.Chars, for: Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  def to_string(%Ast.Pipeline{head: head}) do
    "#{head}"
  end

end
