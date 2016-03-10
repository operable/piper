defmodule Parser.LexerTest do
  use Parser.ParsingCase

  test "lexing whitespace returns empty token list" do
    assert {:ok, []} == Lexer.tokenize(" ", 5)
    assert {:ok, []} == Lexer.tokenize("\n", 5)
    assert {:ok, []} == Lexer.tokenize("\r\n", 5)
  end

  test "lexing symbols" do
    assert matches Lexer.tokenize("[", 5), types(:lbracket)
    assert matches Lexer.tokenize("]", 5), types(:rbracket)
    assert matches Lexer.tokenize(">", 5), types(:redir_one)
    assert matches Lexer.tokenize("*>", 5), types(:redir_multi)
    assert matches Lexer.tokenize("=", 5), types(:equals)
    assert matches Lexer.tokenize("|", 5), types(:pipe)
    assert matches Lexer.tokenize("&&", 5), types(:iff)
  end

  test "lexing plain command" do
    assert matches Lexer.tokenize("echo", 5), types(:string)
  end

  test "lexing hyphenated command" do
    assert matches Lexer.tokenize("list-vms", 5), [types(:string), text("list-vms")]
  end

  test "lexing command with underscore" do
    assert matches Lexer.tokenize("list_vms", 5), [types(:string), text("list_vms")]
  end

  test "lexing numbers" do
    assert matches Lexer.tokenize("123 1072.05 0.05", 5), [types([:integer, :float, :float]),
                                                        text(["123", "1072.05", "0.05"])]
  end

  test "lexing strings that start with numbers" do
    assert matches Lexer.tokenize("0fcaec64-0792-4826-8637-9a50593a7c03", 5), [types([:datum]),
                                                                            text(["0fcaec64-0792-4826-8637-9a50593a7c03"])]
  end

  test "lexing strings that contain commas" do
    assert matches Lexer.tokenize("name,email,username", 5), [types([:datum]), text(["name,email,username"])]
  end

  test "lexing booleans" do
    assert matches Lexer.tokenize("true TRUE false FALSE TrUe FAlse trUE fAlse", 5), [types([:bool, :bool,
                                                                                          :bool, :bool,
                                                                                          :string, :string,
                                                                                          :string, :string])]
    assert matches Lexer.tokenize("echo true false \"testing\"", 5), [types([:string, :bool, :bool, :string])]
  end

  test "lexing plain variables" do
    assert matches Lexer.tokenize("$abc", 5), [types(:variable), text("abc")]
    assert matches Lexer.tokenize("$ABC", 5), [types(:variable), text("ABC")]
    assert matches Lexer.tokenize("$Ab12", 5), [types(:variable), text("Ab12")]
  end

  test "lexing option variable" do
    assert matches Lexer.tokenize("--$abc", 5), [types([:longopt, :variable]), text(["--", "abc"])]
    assert matches Lexer.tokenize("-$abc", 5), [types([:shortopt, :variable]), text(["-", "abc"])]
    assert matches Lexer.tokenize("--$ABC", 5), [types([:longopt, :variable]), text(["--", "ABC"])]
    assert matches Lexer.tokenize("-$ABC", 5), [types([:shortopt, :variable]), text(["-", "ABC"])]
    assert matches Lexer.tokenize("--$AbC12", 5), [types([:longopt, :variable]), text(["--", "AbC12"])]
    assert matches Lexer.tokenize("-$AbC12", 5), [types([:shortopt, :variable]), text(["-", "AbC12"])]
    assert matches Lexer.tokenize("-$A", 5), [types([:shortopt, :variable]), text(["-", "A"])]
  end

  test "lexing long numeric options" do
    assert matches Lexer.tokenize("--foo=123", 5), [types([:longopt, :string, :equals, :integer]),
                                                 text(["--", "foo", "=", "123"])]
    assert matches Lexer.tokenize("--foo=123.33", 5), [types([:longopt, :string, :equals, :float]),
                                                    text(["--", "foo", "=", "123.33"])]
  end

  test "lexing long string-like options" do
    assert matches Lexer.tokenize("--foo=abc", 5), [types([:longopt, :string, :equals, :string]),
                                                 text(["--", "foo", "=", "abc"])]
    assert matches Lexer.tokenize("--foo=\"foo@bar\"", 5), [types([:longopt, :string, :equals, :string]),
                                                         text(["--", "foo", "=", "foo@bar"])]
    assert matches Lexer.tokenize("--foo='foo bar'", 5), [types([:longopt, :string, :equals, :string]),
                                                       text(["--", "foo", "=", "foo bar"])]
    assert matches Lexer.tokenize("--foo=test:test", 5), [types([:longopt, :string, :equals, :string, :colon, :string]),
                                                       text(["--", "foo", "=", "test", ":", "test"])]
  end

  test "lexing long variable options" do
    assert matches Lexer.tokenize("--foo=$bar", 5), [types([:longopt, :string, :equals, :variable]),
                                                  text(["--", "foo", "=", "bar"])]
  end

  test "lexing long numeric optvars" do
    assert matches Lexer.tokenize("--$foo=123", 5), [types([:longopt, :variable, :equals, :integer]),
                                                 text(["--", "foo", "=", "123"])]
    assert matches Lexer.tokenize("--$foo=123.33", 5), [types([:longopt, :variable, :equals, :float]),
                                                     text(["--", "foo", "=", "123.33"])]
  end

  test "lexing long string-like optvars" do
    assert matches Lexer.tokenize("--$foo=abc", 5), [types([:longopt, :variable, :equals, :string]),
                                                 text(["--", "foo", "=", "abc"])]
    assert matches Lexer.tokenize("--$foo=\"foo@bar\"", 5), [types([:longopt, :variable, :equals, :string]),
                                                         text(["--", "foo", "=", "foo@bar"])]
    assert matches Lexer.tokenize("--$foo='foo bar'", 5), [types([:longopt, :variable, :equals, :string]),
                                                       text(["--", "foo", "=", "foo bar"])]
    assert matches Lexer.tokenize("--$foo=test:test", 5), [types([:longopt, :variable, :equals, :string, :colon, :string]),
                                                        text(["--", "foo", "=", "test", ":", "test"])]
  end

  test "lexing long variable optvars" do
    assert matches Lexer.tokenize("--$foo=$bar", 5), [types([:longopt, :variable, :equals, :variable]),
                                                   text(["--", "foo", "=", "bar"])]
  end

  test "lexing short numeric options" do
    assert matches Lexer.tokenize("-f 123", 5), [types([:shortopt, :string, :integer]),
                                              text(["-", "f", "123"])]
    assert matches Lexer.tokenize("-f 123.33", 5), [types([:shortopt, :string, :float]),
                                                 text(["-", "f", "123.33"])]
  end

  test "lexing short string-like options" do
    assert matches Lexer.tokenize("-f abc", 5), [types([:shortopt, :string, :string]),
                                              text(["-", "f", "abc"])]
    assert matches Lexer.tokenize("-f \"foo@bar\"", 5), [types([:shortopt, :string, :string]),
                                                      text(["-", "f", "foo@bar"])]
    assert matches Lexer.tokenize("-f 'foo bar'", 5), [types([:shortopt, :string, :string]),
                                                       text(["-", "f", "foo bar"])]
    assert matches Lexer.tokenize("-f test:test", 5), [types([:shortopt, :string, :string, :colon, :string]),
                                                    text(["-", "f", "test", ":", "test"])]
  end

  test "lexing short variable options" do
    assert matches Lexer.tokenize("-f $bar", 5), [types([:shortopt, :string, :variable]),
                                                    text(["-", "f", "bar"])]

  end

  test "lexing short options with assigned numeric values" do
    assert matches Lexer.tokenize("-f=123", 5), [types([:shortopt, :string, :equals, :integer]),
                                              text(["-", "f", "=", "123"])]
    assert matches Lexer.tokenize("-f=123.33", 5), [types([:shortopt, :string, :equals, :float]),
                                                 text(["-", "f", "=", "123.33"])]
  end

  test "lexing short options with assigned string-like values" do
    assert matches Lexer.tokenize("-f=abc", 5), [types([:shortopt, :string, :equals, :string]),
                                              text(["-", "f", "=", "abc"])]
    assert matches Lexer.tokenize("-f=\"foo@bar\"", 5), [types([:shortopt, :string, :equals, :string]),
                                                      text(["-", "f", "=", "foo@bar"])]
    assert matches Lexer.tokenize("-f='foo bar'", 5), [types([:shortopt, :string, :equals, :string]),
                                                       text(["-", "f", "=", "foo bar"])]
    assert matches Lexer.tokenize("-f=test:test", 5), [types([:shortopt, :string, :equals, :string, :colon, :string]),
                                                    text(["-", "f", "=", "test", ":", "test"])]
  end

  test "lexing short options with assigned variable values" do
    assert matches Lexer.tokenize("-f=$bar", 5), [types([:shortopt, :string, :equals, :variable]),
                                                    text(["-", "f", "=", "bar"])]
  end

  test "lexing short numeric optvars" do
    assert matches Lexer.tokenize("-$f 123", 5), [types([:shortopt, :variable, :integer]),
                                              text(["-", "f", "123"])]
    assert matches Lexer.tokenize("-$f 123.33", 5), [types([:shortopt, :variable, :float]),
                                                  text(["-", "f", "123.33"])]
  end

  test "lexing short string-like optvars" do
    assert matches Lexer.tokenize("-$f abc", 5), [types([:shortopt, :variable, :string]),
                                              text(["-", "f", "abc"])]
    assert matches Lexer.tokenize("-$f \"foo@bar\"", 5), [types([:shortopt, :variable, :string]),
                                                      text(["-", "f", "foo@bar"])]
    assert matches Lexer.tokenize("-$f 'foo bar'", 5), [types([:shortopt, :variable, :string]),
                                                       text(["-", "f", "foo bar"])]
    assert matches Lexer.tokenize("-$f test:test", 5), [types([:shortopt, :variable, :string, :colon, :string]),
                                                       text(["-", "f", "test", ":", "test"])]
  end

  test "lexing short variable optvars" do
    assert matches Lexer.tokenize("-$f $bar", 5), [types([:shortopt, :variable, :variable]),
                                                text(["-", "f", "bar"])]
  end

  test "lexing short optvars with assigned numeric values" do
    assert matches Lexer.tokenize("-$f=123", 5), [types([:shortopt, :variable, :equals, :integer]),
                                               text(["-", "f", "=", "123"])]
    assert matches Lexer.tokenize("-$f=123.33", 5), [types([:shortopt, :variable, :equals, :float]),
                                                  text(["-", "f", "=", "123.33"])]
  end

  test "lexing short optvars with assigned string-like values" do
    assert matches Lexer.tokenize("-$f=abc", 5), [types([:shortopt, :variable, :equals, :string]),
                                              text(["-", "f", "=", "abc"])]
    assert matches Lexer.tokenize("-$f=\"foo@bar\"", 5), [types([:shortopt, :variable, :equals, :string]),
                                                      text(["-", "f", "=", "foo@bar"])]
    assert matches Lexer.tokenize("-$f='foo bar'", 5), [types([:shortopt, :variable, :equals, :string]),
                                                       text(["-", "f", "=", "foo bar"])]
    assert matches Lexer.tokenize("-$f=test:test", 5), [types([:shortopt, :variable, :equals, :string, :colon, :string]),
                                                       text(["-", "f", "=", "test", ":", "test"])]
  end

  test "lexing short optvars with assigned variable value" do
    assert matches Lexer.tokenize("-$f=$bar", 5), [types([:shortopt, :variable, :equals, :variable]),
                                                text(["-", "f", "=", "bar"])]
  end

  test "lexing single-quoted strings" do
    assert matches Lexer.tokenize("'this is a test'", 5), [types(:string), text("this is a test")]
  end

  test "lexing double-quoted strings" do
    assert matches Lexer.tokenize("\"this is a test\"", 5), [types(:string), text("this is a test")]
  end

  test "lexing mixed quotes" do
    assert matches Lexer.tokenize("'\"this is a test\"'", 5), [types(:string), text("\"this is a test\"")]
    assert matches Lexer.tokenize("\"'this is a test'\"", 5), [types(:string), text("'this is a test'")]
  end

  test "lexing escaped quotes" do
    assert matches Lexer.tokenize("\"this is a \\\"test\\\"\"", 5), [types(:string), text("this is a \\\"test\\\"")]
    assert matches Lexer.tokenize("'this is a \\'test\\''", 5), [types(:string), text("this is a \\\'test\\\'")]
  end

  test "lexing quoted terms returns strings" do
    assert matches Lexer.tokenize("\"123\"", 5), [types([:string]), text("123")]
    assert matches Lexer.tokenize("\"0.05\"", 5), [types([:string]), text("0.05")]
    assert matches Lexer.tokenize("'123'", 5), [types([:string]), text("123")]
    assert matches Lexer.tokenize("'$abc_def'", 5), [types([:string]), text("$abc_def")]
    assert matches Lexer.tokenize("'$ab3_Def'", 5), [types([:string]), text("$ab3_Def")]
  end

  test "single-quoted terms remain separate" do
    assert matches Lexer.tokenize("'abc' 'def' '1231'", 5), [types([:string, :string, :string]),
                                                          text(["abc", "def", "1231"])]
    assert matches Lexer.tokenize("'abc''def''1231'", 5), [types([:string, :string, :string]),
                                                        text(["abc", "def", "1231"])]
  end

  test "double-quoted terms remain separate" do
    assert matches Lexer.tokenize("\"abc\" \"def\" \"1231\"", 5), [types([:string, :string, :string]),
                                                                text(["abc", "def", "1231"])]
    assert matches Lexer.tokenize("\"abc\"\"def\"\"1231\"", 5), [types([:string, :string, :string]),
                                                              text(["abc", "def", "1231"])]
  end

  test "embedded newlines are lexed" do
    assert matches Lexer.tokenize("123\n456\n\nabc", 5), [types([:integer, :integer, :string])]
  end

  test "unterminated string causes error" do
    {:error, {:unexpected_input, 10, _}} = Lexer.tokenize("ec2-find \"test-db", 5)
  end

end
