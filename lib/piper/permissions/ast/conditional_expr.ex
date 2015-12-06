defmodule Piper.Permissions.Ast.ConditionalExpr do

  @derive [Poison.Encoder]

  defstruct ['$ast$': "cond_expr", line: nil, col: nil, op: nil, left: nil, right: nil,
             parens: false]

  def new({type, {line, col}, _}, opts \\ []) when type in [:and, :or] do
    lhs = Keyword.get(opts, :left)
    rhs = Keyword.get(opts, :right)
    parens = Keyword.get(opts, :parens, false)
    %__MODULE__{line: line, col: col, op: type, left: lhs,
                right: rhs, parens: parens}
  end

  def update(expr, opts \\ []) do
    lhs = Keyword.get(opts, :left)
    rhs = Keyword.get(opts, :right)
    parens = Keyword.get(opts, :parens)
    expr |>
      update(:left, lhs) |>
      update(:right, rhs) |>
      update(:parens, parens)
  end

  defp update(expr, _, nil) do
    expr
  end
  defp update(expr, :left, lhs) do
    %{expr | left: lhs}
  end
  defp update(expr, :right, rhs) do
    %{expr | right: rhs}
  end
  defp update(expr, :parens, flag) do
    %{expr | parens: flag}
  end

end
