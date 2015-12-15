defmodule Parser.ParserTest do

  # These tests use AST nodes' String.Chars impl as an indirect way
  # of verifying parse tree results

  use Parser.ParsingCase

  defmacrop should_parse(text, ast_text \\ nil, expect \\ true) do
    if ast_text == nil do
      ast_text = text
    end

    quote location: :keep, bind_quoted: [text: text, ast_text: ast_text, expect: expect] do
      expected_ast = Parser.scan_and_parse(text)
      actual_ast = ast_string(ast_text)
      assert matches(expected_ast, actual_ast) == expect
    end
  end

  test "parsing plain command" do
    should_parse "wubba:foo"
    should_parse "foo", "foo:foo"
  end

  test "parsing variable command" do
    should_parse "$foo"
  end

  test "parsing options" do
    should_parse "wubba:foo --bar=1 -f"
    should_parse "foo --bar=1 -f", "foo:foo --bar=1 -f"

    should_parse "$foo --bar=1 -f"

    should_parse "ec2:list-vm --tags=\"a,b,c\" 10", "ec2:list-vm --tags=a,b,c 10"
    should_parse "ec2 --tags=\"a,b,c\" 10", "ec2:ec2 --tags=a,b,c 10"
  end

  test "parsing options referring to names" do
    should_parse "operable:admin perms --grant --permission=operable:write --to=bob"
    should_parse "admin perms --grant --permission=operable:write --to=bob", "admin:admin perms --grant --permission=operable:write --to=bob"
  end

  test "parsing boolean args" do
    should_parse "foo:bar true"
    should_parse "foo true", "foo:foo true"
  end

  test "parsing variable options" do
    should_parse "ec2:list-vm --tags=$tag"
    should_parse "ec2 --tags=$tag", "ec2:ec2 --tags=$tag"
  end

  test "parsing args" do
    should_parse "wubba:foo 123 abc"
    should_parse "foo 123 abc", "foo:foo 123 abc"
  end

  test "parsing double quoted string arguments" do
    should_parse "wubba:foo \"123 abc\"", "wubba:foo 123 abc"
    should_parse "foo \"123 abc\"", "foo:foo 123 abc"
  end

  test "parsing single quoted string arguments" do
    should_parse "wubba:foo '123 abc'", "wubba:foo 123 abc"
    should_parse "foo '123 abc'", "foo:foo 123 abc"
  end

  test "parsing escaped double quoted strings" do
    should_parse "wubba:foo \"123\\\"\" abc", "wubba:foo 123\" abc"
    should_parse "foo \"123\\\"\" abc", "foo:foo 123\" abc"
  end

  test "parsing escaped single quoted strings" do
    should_parse "wubba:foo 123 a\\'b\\'c", "wubba:foo 123 a \\'b\\'c"
    should_parse "foo 123 a\\'b\\'c", "foo:foo 123 a \\'b\\'c"
  end

  test "parsing :pipe pipelines" do
    should_parse "wubba:foo 1 --bar | wubba:baz"
    should_parse "wubba:foo 1 --bar | baz", "wubba:foo 1 --bar | baz:baz"
  end

  test "parsing :iff pipelines" do
    should_parse "wubba:foo --bar && wubba:baz 1"
    should_parse "wubba:foo --bar && baz 1", "wubba:foo --bar && baz:baz 1"
  end

  test "parsing combined pipelines" do
    should_parse "wubba:foo | wubba:bar 500 --limit=2 | wubba:baz"
    should_parse "foo | bar 500 --limit=2 | baz", "foo:foo | bar:bar 500 --limit=2 | baz:baz"
  end
end
