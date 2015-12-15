defmodule Parser.ParserTest do

  # These tests use AST nodes' String.Chars impl as an indirect way
  # of verifying parse tree results

  use Parser.ParsingCase

  @commands [{"wubba:foo", "wubba:foo"},
             {"wubba:foo-bar", "wubba:foo-bar"},
             {"foo", "foo:foo"},
             {"foo-bar", "foo-bar:foo-bar"}]

  defmacrop should_parse(text, ast_text \\ nil, expect \\ true) do
    if ast_text == nil do
      ast_text = text
    end

    if command_used?(text) do
      quote location: :keep do
        for {expected, actual} <- @commands do
          var!(command) = expected
          expected_ast = Parser.scan_and_parse(unquote(text))

          var!(command) = actual
          actual_ast = ast_string(unquote(ast_text))

          assert matches(expected_ast, actual_ast) == unquote(expect)
        end
      end
    else
      quote location: :keep do
        expected_ast = Parser.scan_and_parse(unquote(text))
        actual_ast = ast_string(unquote(ast_text))

        assert matches(expected_ast, actual_ast) == unquote(expect)
      end
    end
  end

  def command_used?(ast) do
    {_, command_used} = Macro.postwalk(ast, false, fn
      {:command, _, nil} = t, acc ->
        {t, acc || true}
      t, acc ->
        {t, acc || false}
    end)

    command_used
  end

  test "parsing plain command" do
    should_parse "#{command}"
  end

  test "parsing variable command" do
    should_parse "$foo"
  end

  test "parsing options" do
    should_parse "#{command} --bar=1 -f"
    should_parse "$foo --bar=1 -f"
    should_parse "#{command} --tags=\"a,b,c\" 10", "#{command} --tags=a,b,c 10"
  end

  test "parsing options referring to names" do
    should_parse "#{command} perms --grant --permission=operable:write --to=bob"
  end

  test "parsing boolean args" do
    should_parse "#{command} true"
  end

  test "parsing variable options" do
    should_parse "#{command} --vm --tags=$tag"
  end

  test "parsing args" do
    should_parse "#{command} 123 abc"
  end

  test "parsing double quoted string arguments" do
    should_parse "#{command} \"123 abc\"", "#{command} 123 abc"
  end

  test "parsing single quoted string arguments" do
    should_parse "#{command} '123 abc'", "#{command} 123 abc"
  end

  test "parsing escaped double quoted strings" do
    should_parse "#{command} \"123\\\"\" abc", "#{command} 123\" abc"
  end

  test "parsing escaped single quoted strings" do
    should_parse "#{command} 123 a\\'b\\'c", "#{command} 123 a \\'b\\'c"
  end

  test "parsing :pipe pipelines" do
    should_parse "#{command} 1 --bar | wubba:baz"
  end

  test "parsing :iff pipelines" do
    should_parse "#{command} --bar && wubba:baz 1"
  end

  test "parsing combined pipelines" do
    should_parse "#{command} | wubba:bar 500 --limit=2 | wubba:baz"
  end

  test "parsing shorthand command" do
    should_parse "foo", "foo:foo"
  end

end
