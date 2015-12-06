defmodule Piper.Permissions.Ast.Rule do

  defstruct [:command_selector, :permission_selector]

  def new(command, perms) do
    %__MODULE__{command_selector: command, permission_selector: perms}
  end

  def command_name(rule) do
    "#{rule.command_selector.right.value}"
  end

end
