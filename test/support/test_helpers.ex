defmodule Parser.TestHelpers do

  alias Piper.Command.SemanticError
  alias Piper.Command.ParserOptions

  def parser_options() do
    %ParserOptions{command_resolver: &resolve_commands/1}
  end

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
