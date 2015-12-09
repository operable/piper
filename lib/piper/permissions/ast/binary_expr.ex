defmodule Piper.Permissions.Ast.BinaryExpr do

  @derive [Poison.Encoder]

  defstruct ['$ast$': "binary_expr", line: nil, col: nil, op: nil, left: nil, right: nil,
             parens: false]

  alias Piper.Permissions.Ast

  def new({type, {line, col}, _}, opts \\ []) when type in [:equiv, :not_equiv,
                                                            :gt, :lt, :gte, :lte,
                                                            :with, :is] do
    lhs = Keyword.get(opts, :left)
    rhs = Keyword.get(opts, :right)
    parens = Keyword.get(opts, :parens, false)
    handle_regex(%__MODULE__{line: line, col: col, op: type, left: lhs,
                             right: rhs, parens: parens})
  end

  def update(expr, opts \\ []) do
    lhs = Keyword.get(opts, :left)
    rhs = Keyword.get(opts, :right)
    parens = Keyword.get(opts, :parens)
    handle_regex(expr |> update(:left, lhs) |> update(:right, rhs) |>
      update(:parens, parens))
  end

  def build(op, left, right) when op in [:equiv, :not_equiv,
                                         :gt, :lt, :gte, :lte,
                                         :with, :is] do
    handle_regex(%__MODULE__{op: op, left: left, right: right, parens: false})
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

  defp handle_regex(%__MODULE__{right: %Ast.Regex{}, op: op}=expr) do
    case op do
      :equiv ->
        %{expr | op: :matches}
      :not_equiv ->
        %{expr | op: :not_matches}
      _ ->
        expr
    end
  end
  defp handle_regex(expr), do: expr

end
