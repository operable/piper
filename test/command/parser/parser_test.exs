defmodule Parser.ParserTest do

  # These tests use AST nodes' String.Chars impl as an indirect way
  # of verifying parse tree results

  alias Parser.TestHelpers
  alias Piper.Command.Ast
  use Parser.ParsingCase

  defp count_or_nil(_count, nil), do: nil
  defp count_or_nil(count, _), do: count

  defmacrop should_parse(text, ast_text \\ nil, stage_count \\ nil) do
    if ast_text == nil do
      ast_text = text
    end
    expect_parse(text, ast_text, true, stage_count)
  end

  defmacrop should_not_parse(text) do
    expect_parse(text, text, false, nil)
  end

  defp expect_parse(text, ast_text, expect, stage_count) do
    if ast_text == nil do
      ast_text = text
    end

    quote bind_quoted: [text: text, ast_text: ast_text, expect: expect, stage_count: stage_count] do
      expected_ast = Parser.scan_and_parse(text)
      actual_ast = ast_string(ast_text)
      assert matches(expected_ast, actual_ast) == expect
      case expected_ast do
        {:ok, ast} ->
          assert count_or_nil(Enum.count(ast), stage_count) == stage_count
        _ ->
          :ok
      end
    end

  end

  test "parsing plain command" do
    should_parse "wubba:foo"
    should_parse "foo", "foo"
    should_parse ":simple_smile:", ":simple_smile:"
    should_parse "foo::simple_smile:", "foo::simple_smile:"
    should_parse "(simple_smile)", "(simple_smile)"
    should_parse "foo:(simple_smile)", "foo:(simple_smile)"
  end

  test "parsing options" do
    should_parse "wubba:foo --bar=1 -f"
    should_parse "foo --bar=1 -f", "foo --bar=1 -f"

    should_parse "ec2:list-vm --tags=\"a,b,c\" 10", "ec2:list-vm --tags=a,b,c 10"
    should_parse "ec2 --tags=\"a,b,c\" 10", "ec2 --tags=a,b,c 10"

    should_parse "foo --bar=testing/testy", "foo --bar=testing/testy"
  end

  test "parsing options referring to names" do
    should_parse "operable:admin perms --grant --permission=operable:write --to=bob"
    should_parse "admin perms --grant --permission=operable:write --to=bob", "admin perms --grant --permission=operable:write --to=bob"
  end

  test "parsing names as args" do
    should_parse "help operable:permissions"
    should_parse "operable:permissions --grant -p operable:write -t bob"
  end

  test "parsing emojis as args" do
    should_parse "help :pageme:"
    should_parse "help (pageme)"
    should_parse "help site::pageme:"
    should_parse "help site:(pageme)"
  end

  test "parsing boolean args" do
    should_parse "foo:bar true", nil, 1
    should_parse "foo true", "foo true", 1
  end

  test "parsing variable options" do
    should_parse "ec2:list-vm --tags=$tag", nil, 1
    should_parse "ec2 --tags=$tag", "ec2 --tags=$tag", 1
  end

  test "parsing args" do
    should_parse "wubba:foo 123 abc", nil, 1
    should_parse "foo 123 abc", "foo 123 abc", 1
  end

  test "parsing double quoted string arguments" do
    should_parse "wubba:foo \"123 abc\"", "wubba:foo 123 abc", 1
    should_parse "foo \"123 abc\"", "foo 123 abc", 1
  end

  test "parsing single quoted string arguments" do
    should_parse "wubba:foo '123 abc'", "wubba:foo 123 abc", 1
    should_parse "foo '123 abc'", "foo 123 abc", 1
  end

  test "using variables for command names should fail" do
    should_not_parse "wubba:$foo"
    should_not_parse "$foo --bar"
  end

  test "parsing :pipe pipelines" do
    should_parse "wubba:foo 1 --bar | wubba:baz", nil, 2
    should_parse "wubba:foo 1 --bar | baz", "wubba:foo 1 --bar | baz", 2
  end

  test "parsing :iff pipelines" do
    should_parse "wubba:foo --bar && wubba:baz 1", nil, 2
    should_parse "wubba:foo --bar && baz 1", "wubba:foo --bar && baz 1", 2
  end

  test "parsing combined pipelines" do
    should_parse "wubba:foo | wubba:bar 500 --limit=2 | wubba:baz", nil, 3
    should_parse "foo | bar 500 --limit=2 | baz", "foo | bar 500 --limit=2 | baz", 3
  end

  test "Output redirection (single)" do
    should_parse "foo:bar --baz > dm", nil, 1
  end

  test "Bad single redirection" do
    should_not_parse "foo:bar --baz > |"
  end

  test "Output redirection (multi)" do
    should_parse "foo:bar --baz *> dm ops", nil, 1
  end

  test "Final redirects are stored on pipeline" do
    {:ok, ast} = Parser.scan_and_parse("foo > me | bar *> me ops")
    assert ast.redirect_to != nil
    assert Enum.count(ast.redirect_to.targets) == 2
    assert Ast.Pipeline.redirect_targets(ast) == ["me", "ops"]
    assert Enum.map(ast.redirect_to.targets, &("#{&1}")) == ["me", "ops"]
  end

  test "resolves ambiguous command names" do
    {:ok, ast} = Parser.scan_and_parse("hello", TestHelpers.parser_options())
    assert "salutations:hello" == "#{ast}"
  end

  test "resolves ambiguous command names in pipelines" do
    {:ok, ast} = Parser.scan_and_parse("hello bobby | goodbye -l", TestHelpers.parser_options())
    assert "salutations:hello bobby | salutations:goodbye -l" == "#{ast}"
  end

  test "non-string/non-emoji bundle name fails resolution" do
    {:error, message} = Parser.scan_and_parse("hello | bogus", TestHelpers.parser_options())
    assert message == "Failed to parse bundle name ':foo' for command 'bogus'. Bundle names must be a string or emoji."
  end

  test "non-string/non-emoji command name fails resolution" do
    {:error, message} = Parser.scan_and_parse("hello | bogus2", TestHelpers.parser_options())
    assert message == "Replacing command name 'bogus2' with ':bogus' failed. Command names must be a string or emoji."
  end

  test "unknown commands fail resolution" do
    {:error, message} = Parser.scan_and_parse("fluff", TestHelpers.parser_options())
    assert message == "Command 'fluff' not found in any installed bundle."
    {:error, message} = Parser.scan_and_parse("hello | goodbye | fluff", TestHelpers.parser_options())
    assert message == "Command 'fluff' not found in any installed bundle."
  end

  test "ambiguous commands fail resolution" do
    {:error, message} = Parser.scan_and_parse("multi", TestHelpers.parser_options())
    assert message ==  "Ambiguous command reference detected. Command 'multi' found in bundles 'a', 'b', and 'c'."
    {:error, message} = Parser.scan_and_parse("hello | multi", TestHelpers.parser_options())
    assert message == "Ambiguous command reference detected. Command 'multi' found in bundles 'a', 'b', and 'c'."
  end

  test "splicing aliases into parse tree" do
    {:ok, ast} = Parser.scan_and_parse("pipe1", TestHelpers.parser_options())
    assert "#{ast}" == "salutations:hello"
  end

  test "splicing aliases into start of parse tree" do
    {:ok, ast} = Parser.scan_and_parse("pipe1 | hello", TestHelpers.parser_options())
    assert "#{ast}" == "salutations:hello | salutations:hello"
  end

  test "splicing aliases into middle of parse tree" do
    {:ok, ast} = Parser.scan_and_parse("goodbye | pipe1 | goodbye", TestHelpers.parser_options())
    assert Enum.count(ast) == 3
    assert "#{ast}" == "salutations:goodbye | salutations:hello | salutations:goodbye"
  end

  test "splicing aliases into end of parse tree" do
    {:ok, ast} = Parser.scan_and_parse("goodbye | hello | pipe1", TestHelpers.parser_options())
    assert Enum.count(ast) == 3
    assert "#{ast}" == "salutations:goodbye | salutations:hello | salutations:hello"
  end

  test "splicing bi-level alias into parse tree" do
    {:ok, ast} = Parser.scan_and_parse("pipe2", TestHelpers.parser_options())
    assert Enum.count(ast) == 1
    assert "#{ast}" == "salutations:hello"
  end

  test "splicing bi-level alias into start of parse tree" do
    {:ok, ast} = Parser.scan_and_parse("goodbye | pipe2", TestHelpers.parser_options())
    assert Enum.count(ast) == 2
    assert "#{ast}" == "salutations:goodbye | salutations:hello"
  end

  test "splicing aliases merges arg lists" do
    {:ok, ast} = Parser.scan_and_parse("goodbye | pipe2 --foo=1 -v --title=Wonka", TestHelpers.parser_options())
    assert Enum.count(ast) == 2
    assert "#{ast}" == "salutations:goodbye | salutations:hello --foo=1 -v --title=Wonka"
    {:ok, ast} = Parser.scan_and_parse("pipe2 --foo=1 | pipe2 -v | goodbye", TestHelpers.parser_options())
    assert Enum.count(ast) == 3
    assert "#{ast}" == "salutations:hello --foo=1 | salutations:hello -v | salutations:goodbye"
  end

  test "splicing aliases with args works" do
    {:ok, ast} = Parser.scan_and_parse("red | blue --count=3 | yellow", TestHelpers.gnarly_options())
    assert "#{ast}" == "colors:red | colors:yellow --action=baa --count=3 | colors:yellow"
  end

  test "splicing multi-level aliases with args works" do
    {:ok, ast} = Parser.scan_and_parse("blue --count=1 | blue --count=2 | blue --count=3 | blue -c=4", TestHelpers.gnarly_options())
    assert "#{ast}" == "colors:yellow --action=baa --count=1 | colors:yellow --action=baa --count=2 | " <>
      "colors:yellow --action=baa --count=3 | colors:yellow --action=baa -c=4"
  end

  test "splicing aliases with redirects works" do
    {:ok, ast} = Parser.scan_and_parse("pepperoni", TestHelpers.redirect_options())
    assert "#{ast}" == "foods:pizza > stomach"
  end

  test "overriding alias redirects works" do
    {:ok, ast} = Parser.scan_and_parse("pepperoni > mouth", TestHelpers.redirect_options())
    assert "#{ast}" == "foods:pizza > mouth"
  end

  test "overriding broadcast alias works" do
    {:ok, ast} = Parser.scan_and_parse("hot_cocoa", TestHelpers.redirect_options())
    assert "#{ast}" == "foods:milk | foods:cocoa | foods:marshmallows *> mug mouth stomach"
    {:ok, ast} = Parser.scan_and_parse("hot_cocoa > friend", TestHelpers.redirect_options())
    assert "#{ast}" == "foods:milk | foods:cocoa | foods:marshmallows > friend"
  end

  test "nested variable reference" do
    should_parse "foo --opt1=$blah[3].wubba", nil, 1
  end

  test "malformed nested variable references fails to parse" do
    should_not_parse "foo --opt1=$blah[3.wubba"
  end

end
