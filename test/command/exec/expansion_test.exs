defmodule Piper.ExpansionTest do

  use ExUnit.Case
  alias Parser.TestHelpers
  alias Piper.Command.Parser

  test "infinite expansion triggers error" do
    {:error, message} = Parser.scan_and_parse("night", TestHelpers.expansion_options())
    assert message == "Infinite alias expansion loop detected 'mare' -> 'night'."
  end

  test "wide infinite expansion is detected" do
    {:error, message} = Parser.scan_and_parse("hello | alpha", TestHelpers.expansion_options())
    assert message == "Infinite alias expansion loop detected 'gamma' -> 'alpha'."
  end

  test "expanding alias with one step" do
    {:ok, ast} = Parser.scan_and_parse("one", TestHelpers.expansion_options())
    assert "#{ast}" == "greetings:hello"
  end

  test "expanding alias with two steps" do
    {:ok, ast} = Parser.scan_and_parse("two", TestHelpers.expansion_options())
    assert "#{ast}" == "greetings:hello"
    {:ok, ast} = Parser.scan_and_parse("two | one | two | two", TestHelpers.expansion_options())
    assert "#{ast}" == "greetings:hello | greetings:hello | greetings:hello | greetings:hello"
  end

  test "expanding aliases at expansion limit" do
    {:ok, ast} = Parser.scan_and_parse("four | three | one | four", TestHelpers.expansion_options())
    assert "#{ast}" == "greetings:hello | greetings:hello | greetings:hello | greetings:hello"
  end

  test "expanding aliases over expansion limit" do
    {:error, message} = Parser.scan_and_parse("seven", TestHelpers.expansion_options())
    assert message == "Alias expansion limit (5) exceeded starting with alias 'seven'."
  end

end
