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

  test "expanding aliases containing variables" do
    {:ok, ast} = Parser.scan_and_parse("prod-buckets | s3:file-info $key", TestHelpers.expansion_options())
    assert "#{ast}" == "s3:list-buckets --region=us-east-1 corp-prod-* | s3:bucket-info $name | s3:file-info $key"
  end

  test "expanding two aliases" do
    {:ok, ast} = Parser.scan_and_parse("prod-buckets | prod-buckets", TestHelpers.expansion_options())
    assert "#{ast}" == "s3:list-buckets --region=us-east-1 corp-prod-* | s3:bucket-info $name | " <>
      "s3:list-buckets --region=us-east-1 corp-prod-* | s3:bucket-info $name"
  end

  test "commands and aliases" do
    {:ok, ast} = Parser.scan_and_parse("s3:pick-region | prod-buckets | raw", TestHelpers.expansion_options())
    assert "#{ast}" == "s3:pick-region | s3:list-buckets --region=us-east-1 corp-prod-* | s3:bucket-info $name | operable:raw"
  end

end
