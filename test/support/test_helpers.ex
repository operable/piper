defmodule Parser.TestHelpers do

  alias Piper.Command.ParserOptions

  def parser_options() do
    %ParserOptions{resolver: &resolve_commands/2}
  end

  def resolve_commands(_bundle, cmd) when cmd in ["hello", "goodbye"] do
    {:command, {"salutations", cmd}}
  end
  def resolve_commands(_bundle, "multi") do
    {:ambiguous, ["a","b","c"]}
  end
  def resolve_commands(_bundle, "bogus") do
    {:command, {":foo", "bogus"}}
  end
  def resolve_commands(_bundle, "bogus2") do
    {:command, {"foo", ":bogus"}}
  end
  def resolve_commands(_bundle, _name) do
    :not_found
  end

end
