defimpl String.Chars, for: Piper.Permissions.Ast.ContainExpr do

  alias Piper.Permissions.Ast

  def to_string(%Ast.ContainExpr{left: left, right: right, parens: parens}) do
    text = "#{left} in #{right}"
    if parens == true do
      "(" <> text <> ")"
    else
      text
    end
  end
end
