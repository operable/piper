defmodule Parser.TestHelpers do

  alias Piper.Command.SemanticError

  def resolve_commands(cmd) when cmd in ["hello", "goodbye"] do
    {:ok, "salutations"}
  end
  def resolve_commands("multi") do
    SemanticError.new("multi", {:ambiguous_command, ["a","b","c"]})
  end
  def resolve_commands("operable:mirror") do
    :identity
  end
  def resolve_commands(name) do
    SemanticError.new(name, :no_command)
  end

end
