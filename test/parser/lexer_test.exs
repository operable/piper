defmodule Parser.LexerTest do

  use Parser.ParsingCase

  test "lexing whitespace returns empty token list" do
    assert {:ok, []} == Lexer.tokenize(" ")
    assert {:ok, []} == Lexer.tokenize("\n")
    assert {:ok, []} == Lexer.tokenize("\r\n")
  end

  test "lexing symbols" do
    assert matches Lexer.tokenize("["), types(:lbracket)
    assert matches Lexer.tokenize("]"), types(:rbracket)
    assert matches Lexer.tokenize(">"), types(:redir)
    assert matches Lexer.tokenize("="), types(:equals)
    assert matches Lexer.tokenize("|"), types(:pipe)
    assert matches Lexer.tokenize("&&"), types(:iff)
  end

  test "lexing plain command" do
    assert matches Lexer.tokenize("echo"), types(:name)
  end

  test "lexing hyphenated command" do
    assert matches Lexer.tokenize("list-vms"), [types(:name), text("list-vms")]
  end

  test "lexing command with underscore" do
    assert matches Lexer.tokenize("list_vms"), [types(:name), text("list_vms")]
  end

  test "lexing invalid commands results in non-name results" do
    assert matches Lexer.tokenize("1list_vms"), [types([:integer, :name]), text(["1", "list_vms"])]
  end

  test "lexing numbers" do
    assert matches Lexer.tokenize("123 1072.05 0.05"), [types([:integer, :float, :float]),
                                                        text(["123", "1072.05", "0.05"])]
  end

  test "lexing booleans" do
    assert matches Lexer.tokenize("true TRUE #t false FALSE #f TrUe FAlse trUE fAlse"), [types([:bool, :bool, :bool,
                                                                                                :bool, :bool, :bool,
                                                                                                :string, :string,
                                                                                                :name, :name])]
    assert matches Lexer.tokenize("echo true false \"testing\""), [types([:name, :bool, :bool, :string])]
  end

  test "lexing plain variables" do
    assert matches Lexer.tokenize("$abc"), [types(:variable), text("abc")]
    assert matches Lexer.tokenize("$ABC"), [types(:variable), text("ABC")]
    assert matches Lexer.tokenize("$Ab12"), [types(:variable), text("Ab12")]
  end

  test "lexing option variable" do
    assert matches Lexer.tokenize("--$abc"), [types(:optvar), text("abc")]
    assert matches Lexer.tokenize("-$abc"), [types(:optvar), text("abc")]
    assert matches Lexer.tokenize("--$ABC"), [types(:optvar), text("ABC")]
    assert matches Lexer.tokenize("-$ABC"), [types(:optvar), text("ABC")]
    assert matches Lexer.tokenize("--$AbC12"), [types(:optvar), text("AbC12")]
    assert matches Lexer.tokenize("-$AbC12"), [types(:optvar), text("AbC12")]
    assert matches Lexer.tokenize("-$A"), [types(:optvar), text("A")]
  end

  test "lexing long numeric options" do
    assert matches Lexer.tokenize("--foo=123"), [types([:option, :equals, :integer]),
                                                 text(["foo", "=", "123"])]
    assert matches Lexer.tokenize("--foo=123.33"), [types([:option, :equals, :float]),
                                                    text(["foo", "=", "123.33"])]
  end

  test "lexing long string-like options" do
    assert matches Lexer.tokenize("--foo=abc"), [types([:option, :equals, :name]),
                                                 text(["foo", "=", "abc"])]
    assert matches Lexer.tokenize("--foo=\"foo@bar\""), [types([:option, :equals, :string]),
                                                         text(["foo", "=", "foo@bar"])]
    assert matches Lexer.tokenize("--foo='foo bar'"), [types([:option, :equals, :string]),
                                                       text(["foo", "=", "foo bar"])]
    assert matches Lexer.tokenize("--foo=test:test"), [types([:option, :equals, :name, :colon, :name]),
                                                       text(["foo", "=", "test", ":", "test"])]
  end

  test "lexing long variable options" do
    assert matches Lexer.tokenize("--foo=$bar"), [types([:option, :equals, :variable]),
                                                  text(["foo", "=", "bar"])]
  end

  test "lexing long numeric optvars" do
    assert matches Lexer.tokenize("--$foo=123"), [types([:optvar, :equals, :integer]),
                                                 text(["foo", "=", "123"])]
    assert matches Lexer.tokenize("--$foo=123.33"), [types([:optvar, :equals, :float]),
                                                     text(["foo", "=", "123.33"])]
  end

  test "lexing long string-like optvars" do
    assert matches Lexer.tokenize("--$foo=abc"), [types([:optvar, :equals, :name]),
                                                 text(["foo", "=", "abc"])]
    assert matches Lexer.tokenize("--$foo=\"foo@bar\""), [types([:optvar, :equals, :string]),
                                                         text(["foo", "=", "foo@bar"])]
    assert matches Lexer.tokenize("--$foo='foo bar'"), [types([:optvar, :equals, :string]),
                                                       text(["foo", "=", "foo bar"])]
    assert matches Lexer.tokenize("--$foo=test:test"), [types([:optvar, :equals, :name, :colon, :name]),
                                                        text(["foo", "=", "test", ":", "test"])]
  end

  test "lexing long variable optvars" do
    assert matches Lexer.tokenize("--$foo=$bar"), [types([:optvar, :equals, :variable]),
                                                   text(["foo", "=", "bar"])]
  end

  test "lexing short numeric options" do
    assert matches Lexer.tokenize("-f 123"), [types([:option, :integer]),
                                              text(["f", "123"])]
    assert matches Lexer.tokenize("-f 123.33"), [types([:option, :float]),
                                                 text(["f", "123.33"])]
  end

  test "lexing short string-like options" do
    assert matches Lexer.tokenize("-f abc"), [types([:option, :name]),
                                              text(["f", "abc"])]
    assert matches Lexer.tokenize("-f \"foo@bar\""), [types([:option, :string]),
                                                      text(["f", "foo@bar"])]
    assert matches Lexer.tokenize("-f 'foo bar'"), [types([:option, :string]),
                                                       text(["f", "foo bar"])]
    assert matches Lexer.tokenize("-f test:test"), [types([:option, :name, :colon, :name]),
                                                    text(["f", "test", ":", "test"])]
  end

  test "lexing short variable options" do
    assert matches Lexer.tokenize("-f $bar"), [types([:option, :variable]),
                                                    text(["f", "bar"])]

  end

  test "lexing short options with assigned numeric values" do
    assert matches Lexer.tokenize("-f=123"), [types([:option, :equals, :integer]),
                                              text(["f", "=", "123"])]
    assert matches Lexer.tokenize("-f=123.33"), [types([:option, :equals, :float]),
                                                 text(["f", "=", "123.33"])]
  end

  test "lexing short options with assigned string-like values" do
    assert matches Lexer.tokenize("-f=abc"), [types([:option, :equals, :name]),
                                              text(["f", "=", "abc"])]
    assert matches Lexer.tokenize("-f=\"foo@bar\""), [types([:option, :equals, :string]),
                                                      text(["f", "=", "foo@bar"])]
    assert matches Lexer.tokenize("-f='foo bar'"), [types([:option, :equals, :string]),
                                                       text(["f", "=", "foo bar"])]
    assert matches Lexer.tokenize("-f=test:test"), [types([:option, :equals, :name, :colon, :name]),
                                                    text(["f", "=", "test", ":", "test"])]
  end

  test "lexing short options with assigned variable values" do
    assert matches Lexer.tokenize("-f=$bar"), [types([:option, :equals, :variable]),
                                                    text(["f", "=", "bar"])]
  end

  test "lexing short numeric optvars" do
    assert matches Lexer.tokenize("-$f 123"), [types([:optvar, :integer]),
                                              text(["f", "123"])]
    assert matches Lexer.tokenize("-$f 123.33"), [types([:optvar, :float]),
                                                  text(["f", "123.33"])]
  end

  test "lexing short string-like optvars" do
    assert matches Lexer.tokenize("-$f abc"), [types([:optvar, :name]),
                                              text(["f", "abc"])]
    assert matches Lexer.tokenize("-$f \"foo@bar\""), [types([:optvar, :string]),
                                                      text(["f", "foo@bar"])]
    assert matches Lexer.tokenize("-$f 'foo bar'"), [types([:optvar, :string]),
                                                       text(["f", "foo bar"])]
    assert matches Lexer.tokenize("-$f test:test"), [types([:optvar, :name, :colon, :name]),
                                                       text(["f", "test", ":", "test"])]
  end

  test "lexing short variable optvars" do
    assert matches Lexer.tokenize("-$f $bar"), [types([:optvar, :variable]),
                                                text(["f", "bar"])]
  end

  test "lexing short optvars with assigned numeric values" do
    assert matches Lexer.tokenize("-$f=123"), [types([:optvar, :equals, :integer]),
                                               text(["f", "=", "123"])]
    assert matches Lexer.tokenize("-$f=123.33"), [types([:optvar, :equals, :float]),
                                                  text(["f", "=", "123.33"])]
  end

  test "lexing short optvars with assigned string-like values" do
    assert matches Lexer.tokenize("-$f=abc"), [types([:optvar, :equals, :name]),
                                              text(["f", "=", "abc"])]
    assert matches Lexer.tokenize("-$f=\"foo@bar\""), [types([:optvar, :equals, :string]),
                                                      text(["f", "=", "foo@bar"])]
    assert matches Lexer.tokenize("-$f='foo bar'"), [types([:optvar, :equals, :string]),
                                                       text(["f", "=", "foo bar"])]
    assert matches Lexer.tokenize("-$f=test:test"), [types([:optvar, :equals, :name, :colon, :name]),
                                                       text(["f", "=", "test", ":", "test"])]
  end

  test "lexing short optvars with assigned variable value" do
    assert matches Lexer.tokenize("-$f=$bar"), [types([:optvar, :equals, :variable]),
                                                text(["f", "=", "bar"])]
  end

  test "lexing single-quoted strings" do
    assert matches Lexer.tokenize("'this is a test'"), [types(:string), text("this is a test")]
  end

  test "lexing double-quoted strings" do
    assert matches Lexer.tokenize("\"this is a test\""), [types(:string), text("this is a test")]
  end

  test "lexing mixed quotes" do
    assert matches Lexer.tokenize("'\"this is a test\"'"), [types(:string), text("\"this is a test\"")]
    assert matches Lexer.tokenize("\"'this is a test'\""), [types(:string), text("'this is a test'")]
  end

  test "lexing escaped quotes" do
    assert matches Lexer.tokenize("\"this is a \\\"test\\\"\""), [types(:string), text("this is a \"test\"")]
    assert matches Lexer.tokenize("'this is a \\'test\\''"), [types(:string), text("this is a 'test'")]
  end

  test "lexing quoted terms returns strings" do
    assert matches Lexer.tokenize("\"123\""), [types([:string]), text("123")]
    assert matches Lexer.tokenize("\"0.05\""), [types([:string]), text("0.05")]
    assert matches Lexer.tokenize("'123'"), [types([:string]), text("123")]
    assert matches Lexer.tokenize("'$abc_def'"), [types([:string]), text("$abc_def")]
    assert matches Lexer.tokenize("'$ab3_Def'"), [types([:string]), text("$ab3_Def")]
  end

  test "single-quoted terms remain separate" do
    assert matches Lexer.tokenize("'abc' 'def' '1231'"), [types([:string, :string, :string]),
                                                          text(["abc", "def", "1231"])]
    assert matches Lexer.tokenize("'abc''def''1231'"), [types([:string, :string, :string]),
                                                        text(["abc", "def", "1231"])]
  end

  test "double-quoted terms remain separate" do
    assert matches Lexer.tokenize("\"abc\" \"def\" \"1231\""), [types([:string, :string, :string]),
                                                                text(["abc", "def", "1231"])]
    assert matches Lexer.tokenize("\"abc\"\"def\"\"1231\""), [types([:string, :string, :string]),
                                                              text(["abc", "def", "1231"])]
  end

  test "embedded newlines are lexed" do
    assert matches Lexer.tokenize("123\n456\n\nabc"), [types([:integer, :integer, :name])]
  end

  test "unterminated string causes error" do
    {:error, {:unexpected_input, 10, _}} = Lexer.tokenize("ec2-find \"test-db")
  end

end
