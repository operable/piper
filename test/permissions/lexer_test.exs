defmodule Piper.Permissions.LexerTest do

  use ExUnit.Case

  defp fails(text) do
    {:error, _, _} = :piper_rule_lexer.tokenize(text)
  end

  defp matches(text, token_spec) do
    {:ok, tokens} = :piper_rule_lexer.tokenize(text)
    assert length(tokens) == length(token_spec)
    evaluate_spec(token_spec, tokens)
  end

  defp evaluate_spec([], _) do
    :ok
  end
  defp evaluate_spec([{type, text}|st], [{token_type, _, token_text}|tt]) do
    if type != token_type do
      raise RuntimeError, message: "Expected token type #{inspect type} but found #{inspect token_type}"
    end
    if text != token_text do
      raise RuntimeError, message: "Expected token value #{inspect text} but found #{inspect token_text}"
    end
    evaluate_spec(st, tt)
  end
  defp evaluate_spec([type|st], [{token_type, _, _}|tt]) do
    if type != token_type do
      raise RuntimeError, message: "Expected token type #{inspect type} but found #{inspect token_type}"
    end
    evaluate_spec(st, tt)
  end

  # Force Erlang modules to be reloaded in case tests are being
  # run via mix test.watch
  setup_all do
    for m <- [:piper_rule_lexer, :piper_rule_parser] do
      :code.purge(m)
      :code.delete(m)
      {:module, _} = Code.ensure_compiled(m)
    end
    :ok
  end

  test "tokenizing reserved words" do
    matches "when with must have command any all", [:when, :with, :must, :have, :command, :any, :all]
  end

  test "tokenizing booleans" do
    matches "true false", [boolean: true, boolean: false]
  end

  test "tokenizing args" do
    matches "arg", [arg: nil]
    matches "arg[0]", [arg: 0]
    matches "arg[]", [:arg, :lbracket, :rbracket]
  end

  test "tokenizing numeric values" do
    matches "123", [integer: 123]
    matches "012312", [integer: 12312]
    matches "0.55", [float: 0.55]
    fails ".55"
  end

  test "tokenizing strings" do
    matches "this_is_a_test", [name: 'this_is_a_test']
    matches "testing 123", [name: 'testing', integer: 123]
    matches "\"this is a test\"", [dqstring: 'this is a test']
    matches "'this is a test'", [sqstring: 'this is a test']
  end

  test "quoting other types" do
    matches "\"true\"", [dqstring: 'true']
    matches "'false'", [sqstring: 'false']
    matches "\"10005\"", [dqstring: '10005']
    matches "'0.55'", [sqstring: '0.55']
    matches "\".55\"", [dqstring: '.55']
  end

  test "quoting namespaced names" do
    matches "\"foo:bar\"", [dqstring: 'foo:bar']
    matches "'foo:bar'", [sqstring: 'foo:bar']
    matches "\"foo:bar:\"", [dqstring: 'foo:bar:']
    matches "'foo:bar:'", [sqstring: 'foo:bar:']
  end

  test "quoting quoted strings" do
    matches "\"\\\"this is a test\\\"\"", [dqstring: '\\\"this is a test\\\"']
    matches "\"'this is a test'\"", [dqstring: '\'this is a test\'']
    matches "'\"this is a test\"'", [sqstring: '\"this is a test\"']
    matches "'this is a test''so is this'", [sqstring: 'this is a test', sqstring: 'so is this']
    matches "\"this is a test\"\"so is this\"", [dqstring: 'this is a test', dqstring: 'so is this']
  end

  test "tokenizing operators" do
    matches "< > =< >=", [:lt, :gt, :lte, :gte]
    matches "!= ==", [:not_equiv, :equiv]
    matches "and or not in", [:and, :or, :not, :in]
  end

  test "tokenizing regexes" do
    matches "/foo:ba[0-9]/", [regex: 'foo:ba[0-9]']
    fails "/foo:ba[0-9]"
  end

  test "tokenizing lists" do
    matches "[1,2,3]", [:lbracket, {:integer, 1}, :comma, {:integer, 2}, :comma,
                        {:integer, 3}, :rbracket]
  end

  test "tokenizing namespaced names" do
    matches "foo:bar", [name: 'foo', colon: ':', name: 'bar']
    matches "foo::bar:", [name: 'foo', colon: ':', emoji: ':bar:']
    matches "foo:(bar)", [name: 'foo', colon: ':', emoji: '(bar)']
  end

end
