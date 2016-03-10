defmodule Parser.TestHelpers do

  alias Piper.Command.ParserOptions

  def parser_options() do
    %ParserOptions{resolver: &resolve_commands/2}
  end

  def expansion_options() do
    %ParserOptions{resolver: &expand_commands/2}
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
  def resolve_commands(_bundle, "pipe2") do
    {:pipeline, "pipe1"}
  end
  def resolve_commands(_bundle, "pipe1") do
    {:pipeline, "hello"}
  end
  def resolve_commands(_bundle, _name) do
    :not_found
  end

  def expand_commands(_bundle, "night") do
    {:pipeline, "mare"}
  end
  def expand_commands(_bundle, "mare") do
    {:pipeline, "hello | night"}
  end
  def expand_commands(_bundle, "one") do
    {:pipeline, "hello"}
  end
  def expand_commands(_bundle, "two") do
    {:pipeline, "one"}
  end
  def expand_commands(_bundle, "three") do
    {:pipeline, "two"}
  end
  def expand_commands(_bundle, "four") do
    {:pipeline, "three"}
  end
  def expand_commands(_bundle, "five") do
    {:pipeline, "four"}
  end
  def expand_commands(_bundle, "six") do
    {:pipeline, "five"}
  end
  def expand_commands(_bundle, "seven") do
    {:pipeline, "seven"}
  end
  def expand_commands(_bundle, cmd) when cmd in ["hello"] do
    {:command, {"greetings", cmd}}
  end

end
