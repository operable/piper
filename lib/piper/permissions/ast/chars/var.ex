defimpl String.Chars, for: Piper.Permissions.Ast.Var do

  alias Piper.Permissions.Ast

  def to_string(%Ast.Var{name: name}) do
    name
  end

end
