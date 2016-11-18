defmodule Parser.TestHelpers do

  alias Piper.Command.ParserOptions

  def parser_options(use_legacy \\ false) do
    %ParserOptions{resolver: &resolve_commands/2,
                   use_legacy_parser: use_legacy}
  end

  def expansion_options(use_legacy \\ false) do
    %ParserOptions{resolver: &expand_commands/2,
                   use_legacy_parser: use_legacy}
  end

  def gnarly_options(use_legacy \\ false) do
    %ParserOptions{resolver: &gnarly_expansions/2,
                   use_legacy_parser: use_legacy}
  end

  def redirect_options(use_legacy \\ false) do
    %ParserOptions{resolver: &redirect_expansions/2,
                   use_legacy_parser: use_legacy}
  end

  def hyphenated_command_options(use_legacy \\ false) do
    %ParserOptions{resolver: &resolve_hyphenated_commands/2,
                   use_legacy_parser: use_legacy}
  end

  def longest_hyphenated_command_options(use_legacy \\ false) do
    %ParserOptions{resolver: &resolve_longest_hyphenated_commands/2,
                   use_legacy_parser: use_legacy}
  end


  def long_command_options(use_legacy \\ false) do
    %ParserOptions{resolver: &resolve_long_commands/2,
                   use_legacy_parser: use_legacy}
  end

  def resolve_hyphenated_commands(bundle, cmd) do
    if String.contains?(cmd, "-") do
      {:command, {bundle, cmd}}
    else
      {:error, :not_found}
    end
  end

  def resolve_longest_hyphenated_commands(_bundle, cmd) do
      case cmd do
        "stacks-ls-prod" ->
          {:command, {"cfn", cmd}}
        "stacks-ls" ->
          {:command, {"cfn", cmd}}
        "ls-prod" ->
          {:error, {:ambiguous, ["ec2", "cfn"]}}
        _ ->
        {:error, :not_found}
    end
  end

  def resolve_long_commands(_bundle, cmd) do
    case String.split(cmd, "-") do
      ["stack", "purge", "delete"] ->
        {:command, {"cfn", cmd}}
      _ ->
        {:error, :not_found}
    end
  end

  def resolve_commands(_bundle, cmd) when cmd in ["hello", "goodbye"] do
    {:command, {"salutations", cmd}}
  end
  def resolve_commands(_bundle, "multi") do
    {:error, {:ambiguous, ["a","b","c"]}}
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
  def resolve_commands(_bundle, "not_enabled") do
    {:error, {:not_enabled, "bundle1"}}
  end
  def resolve_commands(_bundle, "not_in_bundle") do
    {:error, {:not_in_bundle, "bundle1"}}
  end
  def resolve_commands(_bundle, _name) do
    {:error, :not_found}
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
  def expand_commands(_bundle, "alpha") do
    {:pipeline, "beta"}
  end
  def expand_commands(_bundle, "beta") do
    {:pipeline, "gamma"}
  end
  def expand_commands(_bundle, "gamma") do
    {:pipeline, "alpha"}
  end
  def expand_commands(_bundle, cmd) when cmd in ["hello"] do
    {:command, {"greetings", cmd}}
  end
  def expand_commands(_bundle, "raw") do
    {:command, {"operable", "raw"}}
  end
  def expand_commands(_bundle, "prod-buckets") do
    {:pipeline, "s3:list-buckets --region=us-east-1 corp-prod-* | s3:bucket-info $name"}
  end
  def expand_commands("s3", command) do
    {:command, {"s3", command}}
  end

  def gnarly_expansions(_bundle, color) when color in ["red", "yellow"] do
    {:command, {"colors", color}}
  end
  def gnarly_expansions(_bundle, "green") do
    {:pipeline, "blue --title=moo | yellow"}
  end
  def gnarly_expansions(_bundle, "blue") do
    {:pipeline, "yellow --action=baa"}
  end

  def redirect_expansions(_bundle, food) when food in ["pizza", "milk", "cocoa", "marshmallows"] do
    {:command, {"foods", food}}
  end
  def redirect_expansions(_bundle, "pepperoni") do
    {:pipeline, "foods:pizza > stomach"}
  end
  def redirect_expansions(_bundle, "hot_cocoa") do
    {:pipeline, "milk | cocoa | marshmallows *> mug mouth stomach"}
  end

end
