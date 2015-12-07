defmodule Piper.Permissions.Ast.Json.Util do

  alias Piper.Permissions.Ast

  def map_to_empty_struct(value) do
    value
    |> Map.fetch!("$ast$")
    |> struct_for_ast_type
  end

  defp struct_for_ast_type("rule"), do: %Ast.Rule{}
  defp struct_for_ast_type("binary_expr"), do: %Ast.BinaryExpr{}
  defp struct_for_ast_type("cond_expr"), do: %Ast.ConditionalExpr{}
  defp struct_for_ast_type("contain_expr"), do: %Ast.ContainExpr{}
  defp struct_for_ast_type("perm_expr"), do: %Ast.PermissionExpr{}
  defp struct_for_ast_type("string"), do: %Ast.String{}
  defp struct_for_ast_type("integer"), do: %Ast.Integer{}
  defp struct_for_ast_type("float"), do: %Ast.Float{}
  defp struct_for_ast_type("bool"), do: %Ast.Bool{}
  defp struct_for_ast_type("array"), do: %Ast.List{}
  defp struct_for_ast_type("regex"), do: %Ast.Regex{}
  defp struct_for_ast_type("arg"), do: %Ast.Arg{}
  defp struct_for_ast_type("option"), do: %Ast.Option{}
  defp struct_for_ast_type("var"), do: %Ast.Var{}

end
