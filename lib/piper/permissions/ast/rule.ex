defmodule Piper.Permissions.Ast.Rule do

  alias Piper.Permissions.Ast

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "rule"}, :command, :command_selector, :permission_selector, :score]

  def new(cmd_selector, perm_selector) do
    command = find_command_name(cmd_selector)
    if command == nil do
      raise "Cannot determine command name from #{cmd_selector}"
    end
    %__MODULE__{command_selector: cmd_selector, permission_selector: perm_selector, command: command}
  end

  def command_name(rule) do
    rule.command
  end

  def find_command_name(%Ast.BinaryExpr{left: %Ast.Var{name: "command"}, right: right, op: :is}) do
    right.value
  end
  def find_command_name(%Ast.BinaryExpr{left: left, right: right}) do
    result = find_command_name(left)
    if result == nil do
      find_command_name(right)
    else
      result
    end
  end
  def find_command_name(_), do: nil

  def permissions_used(rule = %__MODULE__{}) do
    Enum.sort(permissions_used(rule.permission_selector, []))
  end

  def permissions_used(nil, accum) do
    accum
  end
  def permissions_used(%Ast.PermissionExpr{perms: %Ast.List{values: values}}, accum) do
    Enum.reduce(values, accum, fn(v, acc) ->
      if Enum.member?(acc, v.value) do
        accum
      else
        [v.value|acc]
      end end)
  end
  def permissions_used(%Ast.PermissionExpr{perms: %Ast.String{value: name}}, accum) do
    if Enum.member?(accum, name) do
      accum
    else
      [name|accum]
    end
  end
  def permissions_used(expr, accum) do
    accum = permissions_used(Map.get(expr, :left), accum)
    permissions_used(Map.get(expr, :right), accum)
  end
end
