defimpl String.Chars, for: Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  def to_string(%Ast.Pipeline{stages: stages}) do
    "#{stages}"
  end

end
