defimpl String.Chars, for: Piper.Permissions.Ast.ConditionalExpr do

  alias Piper.Permissions.Ast

  def to_string(%Ast.ConditionalExpr{parens: parens, left: lhs, right: rhs, op: op}) do
    text = "#{lhs} #{op} #{rhs}"
    if parens == true do
      "(" <> text <> ")"
    else
      text
    end
  end

end
