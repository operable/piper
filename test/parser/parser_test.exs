defmodule Parser.ParserTest do

  # These tests use AST nodes' String.Chars impl as an indirect way
  # of verifying parse tree results

  use Parser.ParsingCase

  test "parsing plain command" do
    assert matches Parser.scan_and_parse("foo"), ast_string("foo")
  end

  test "parsing variable command" do
    assert matches Parser.scan_and_parse("$foo"), ast_string("$foo")
  end

  test "parsing options" do
    assert matches Parser.scan_and_parse("foo --bar=1 -f"), ast_string("foo --bar=1 -f")
    assert matches Parser.scan_and_parse("$foo --bar=1 -f"), ast_string("$foo --bar=1 -f")
    assert matches Parser.scan_and_parse("ec2:list-vm --tags=\"a,b,c\" 10"), ast_string("ec2:list-vm --tags=\"a,b,c\" 10")
  end

  test "parsing variable options" do
    assert matches Parser.scan_and_parse("ec2:list-vm --tags=$tag"), ast_string("ec2:list-vm --tags=$tag")
  end

  test "parsing args" do
    assert matches Parser.scan_and_parse("foo 123 abc"), ast_string("foo 123 abc")
  end

  test "parsing double quoted string arguments" do
    assert matches Parser.scan_and_parse("foo \"123 abc\""), ast_string("foo \"123 abc\"")
  end

  test "parsing single quoted string arguments" do
    assert matches Parser.scan_and_parse("foo '123 abc'"), ast_string("foo '123 abc'")
  end

  test "parsing escaped double quoted strings" do
    assert matches Parser.scan_and_parse("foo \"123\\\" abc\""), ast_string("foo \"123\\\" abc\"")
  end

  test "parsing escaped single quoted strings" do
    assert matches Parser.scan_and_parse("foo '123 a\\'b\\'c'"), ast_string("foo '123 a\\'b\\'c'")
  end

  test "parsing :pipe pipelines" do
    assert matches Parser.scan_and_parse("wubba:foo 1 --bar | baz"), ast_string("wubba:foo 1 --bar | baz")
  end

  test "parsing :iff pipelines" do
    assert matches Parser.scan_and_parse("wubba:foo --bar && baz 1"), ast_string("wubba:foo --bar && baz 1")
  end

  test "parsing combined pipelines" do
    assert matches Parser.scan_and_parse("foo | bar 500 --limit=2 | baz"), ast_string("foo | bar 500 --limit=2 | baz")
  end

end
