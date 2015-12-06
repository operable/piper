defmodule Piper.Permissions.Ast.ContainExpr do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "contain_expr"}, :line, :col, :lhs_agg, :left, :right, :parens]

  alias Piper.Permissions.Ast

  def new({:in, {line, col}, _}, %Ast.Arg{}=lhs, %Ast.List{}=rhs) do
    %__MODULE__{line: line, col: col, left: lhs, right: rhs,
                lhs_agg: aggregate_type(lhs.index)}
  end
  def new({:in, {line, col}, _}, %Ast.Option{}=lhs, %Ast.List{}=rhs) do
    %__MODULE__{line: line, col: col, left: lhs, right: rhs,
                lhs_agg: aggregate_type(lhs.name)}
  end

  defp aggregate_type(type) when type in [:any, :all] do
    true
  end
  defp aggregate_type(_) do
    false
  end

  def update(expr, parens: flag) do
    %{expr | parens: flag}
  end
end
