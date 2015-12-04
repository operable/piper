defimpl String.Chars, for: Piper.Permissions.Ast.Rule do

  alias Piper.Permissions.Ast

  def to_string(%Ast.Rule{command_selector: cs, permission_selector: ps}) do
    "when #{cs} must have #{ps}"
  end

end
