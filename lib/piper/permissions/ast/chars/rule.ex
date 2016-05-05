defimpl String.Chars, for: Piper.Permissions.Ast.Rule do

  alias Piper.Permissions.Ast

  def to_string(%Ast.Rule{command_selector: cs, permission_selector: ps}) do
    "when #{cs} #{ps_str(ps)}"
  end

  defp ps_str(%Ast.ConditionalExpr{op: :allow}=ps),
    do: "#{ps}"
  defp ps_str(ps),
    do: "must have #{ps}"

end
