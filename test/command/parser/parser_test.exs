defmodule Parser.ParserTest do

  # These tests use AST nodes' String.Chars impl as an indirect way
  # of verifying parse tree results

  use Parser.ParsingCase

  defmacrop should_parse(text, ast_text \\nil, expect \\ true) do
    if ast_text == nil do
      ast_text = text
    end
    quote location: :keep do
      assert matches(Parser.scan_and_parse(unquote(text)), ast_string(unquote(ast_text))) == unquote(expect)
    end
  end

  test "parsing plain command" do
    should_parse "wubba:foo"
  end

  test "parsing variable command" do
    should_parse "$foo"
  end

  test "parsing options" do
    should_parse "wubba:foo --bar=1 -f"
    should_parse "$foo --bar=1 -f"
    should_parse "ec2:list-vm --tags=\"a,b,c\" 10", "ec2:list-vm --tags=a,b,c 10"
  end

  test "parsing options referring to names" do
    should_parse "operable:admin perms --grant --permission=operable:write --to=bob"
  end

  test "parsing boolean args" do
    should_parse "foo:bar true"
  end

  test "parsing variable options" do
    should_parse "ec2:list-vm --tags=$tag"
  end

  test "parsing args" do
    should_parse "wubba:foo 123 abc"
  end

  test "parsing double quoted string arguments" do
    should_parse "wubba:foo \"123 abc\"", "wubba:foo 123 abc"
  end

  test "parsing single quoted string arguments" do
    should_parse "wubba:foo '123 abc'", "wubba:foo 123 abc"
  end

  test "parsing escaped double quoted strings" do
    should_parse "wubba:foo \"123\\\"\" abc", "wubba:foo 123\" abc"
  end

  test "parsing escaped single quoted strings" do
    should_parse "wubba:foo 123 a\\'b\\'c", "wubba:foo 123 a \\'b\\'c"
  end

  test "parsing :pipe pipelines" do
    should_parse "wubba:foo 1 --bar | wubba:baz"
  end

  test "parsing :iff pipelines" do
    should_parse "wubba:foo --bar && wubba:baz 1"
  end

  test "parsing combined pipelines" do
    should_parse "wubba:foo | wubba:bar 500 --limit=2 | wubba:baz"
  end

  test "parsing shorthand command" do
    should_parse "foo", "foo:foo"
  end

end
