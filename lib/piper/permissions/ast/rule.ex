defmodule Piper.Permissions.Ast.Rule do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "rule"}, :command_selector, :permission_selector]

  def new(command, perms) do
    %__MODULE__{command_selector: command, permission_selector: perms}
  end

  def command_name(nil) do
    nil
  end
  def command_name(rule) do
    if rule.command_selector != nil and
       rule.command_selector.right != nil do
    "#{rule.command_selector.right.value}"
    else
      nil
    end
  end

end
