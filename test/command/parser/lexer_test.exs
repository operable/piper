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
    assert matches Lexer.tokenize(">"), types(:redir_one)
    assert matches Lexer.tokenize("*>"), types(:redir_multi)
    assert matches Lexer.tokenize("="), types(:equals)
    assert matches Lexer.tokenize("|"), types(:pipe)
    assert matches Lexer.tokenize("&&"), types(:iff)
  end

  test "lexing plain command" do
    assert matches Lexer.tokenize("echo"), types(:string)
  end

  test "lexing hyphenated command" do
    assert matches Lexer.tokenize("list-vms"), [types(:string), text("list-vms")]
  end

  test "lexing command with underscore" do
    assert matches Lexer.tokenize("list_vms"), [types(:string), text("list_vms")]
  end

  test "lexing numbers" do
    assert matches Lexer.tokenize("123 1072.05 0.05"), [types([:integer, :float, :float]),
                                                        text(["123", "1072.05", "0.05"])]
  end

  test "lexing strings that start with numbers" do
    assert matches Lexer.tokenize("0fcaec64-0792-4826-8637-9a50593a7c03"), [types([:string]),
                                                                            text(["0fcaec64-0792-4826-8637-9a50593a7c03"])]
  end

  test "lexing strings that contain commas" do
    assert matches Lexer.tokenize("name,email,username"), [types([:string]), text(["name,email,username"])]
  end

  test "lexing booleans" do
    assert matches Lexer.tokenize("true TRUE #t false FALSE #f TrUe FAlse trUE fAlse"), [types([:bool, :bool, :bool,
                                                                                                :bool, :bool, :bool,
                                                                                                :string, :string,
                                                                                                :string, :string])]
    assert matches Lexer.tokenize("echo true false \"testing\""), [types([:string, :bool, :bool, :quoted_string])]
  end

  test "lexing plain variables" do
    assert matches Lexer.tokenize("$abc"), [types(:variable), text("abc")]
    assert matches Lexer.tokenize("$ABC"), [types(:variable), text("ABC")]
    assert matches Lexer.tokenize("$Ab12"), [types(:variable), text("Ab12")]
  end

  test "lexing option variable" do
    assert matches Lexer.tokenize("--$abc"), [types([:option, :variable]), text(["--", "abc"])]
    assert matches Lexer.tokenize("-$abc"), [types([:option, :variable]), text(["-", "abc"])]
    assert matches Lexer.tokenize("--$ABC"), [types([:option, :variable]), text(["--", "ABC"])]
    assert matches Lexer.tokenize("-$ABC"), [types([:option, :variable]), text(["-", "ABC"])]
    assert matches Lexer.tokenize("--$AbC12"), [types([:option, :variable]), text(["--", "AbC12"])]
    assert matches Lexer.tokenize("-$AbC12"), [types([:option, :variable]), text(["-", "AbC12"])]
    assert matches Lexer.tokenize("-$A"), [types([:option, :variable]), text(["-", "A"])]
  end

  test "lexing long numeric options" do
    assert matches Lexer.tokenize("--foo=123"), [types([:option, :string, :equals, :integer]),
                                                 text(["--", "foo", "=", "123"])]
    assert matches Lexer.tokenize("--foo=123.33"), [types([:option, :string, :equals, :float]),
                                                    text(["--", "foo", "=", "123.33"])]
  end

  test "lexing long string-like options" do
    assert matches Lexer.tokenize("--foo=abc"), [types([:option, :string, :equals, :string]),
                                                 text(["--", "foo", "=", "abc"])]
    assert matches Lexer.tokenize("--foo=\"foo@bar\""), [types([:option, :string, :equals, :quoted_string]),
                                                         text(["--", "foo", "=", "foo@bar"])]
    assert matches Lexer.tokenize("--foo='foo bar'"), [types([:option, :string, :equals, :quoted_string]),
                                                       text(["--", "foo", "=", "foo bar"])]
    assert matches Lexer.tokenize("--foo=test:test"), [types([:option, :string, :equals, :string, :colon, :string]),
                                                       text(["--", "foo", "=", "test", ":", "test"])]
  end

  test "lexing long variable options" do
    assert matches Lexer.tokenize("--foo=$bar"), [types([:option, :string, :equals, :variable]),
                                                  text(["--", "foo", "=", "bar"])]
  end

  test "lexing long numeric optvars" do
    assert matches Lexer.tokenize("--$foo=123"), [types([:option, :variable, :equals, :integer]),
                                                 text(["--", "foo", "=", "123"])]
    assert matches Lexer.tokenize("--$foo=123.33"), [types([:option, :variable, :equals, :float]),
                                                     text(["--", "foo", "=", "123.33"])]
  end

  test "lexing long string-like optvars" do
    assert matches Lexer.tokenize("--$foo=abc"), [types([:option, :variable, :equals, :string]),
                                                 text(["--", "foo", "=", "abc"])]
    assert matches Lexer.tokenize("--$foo=\"foo@bar\""), [types([:option, :variable, :equals, :quoted_string]),
                                                         text(["--", "foo", "=", "foo@bar"])]
    assert matches Lexer.tokenize("--$foo='foo bar'"), [types([:option, :variable, :equals, :quoted_string]),
                                                       text(["--", "foo", "=", "foo bar"])]
    assert matches Lexer.tokenize("--$foo=test:test"), [types([:option, :variable, :equals, :string, :colon, :string]),
                                                        text(["--", "foo", "=", "test", ":", "test"])]
  end

  test "lexing long variable optvars" do
    assert matches Lexer.tokenize("--$foo=$bar"), [types([:option, :variable, :equals, :variable]),
                                                   text(["--", "foo", "=", "bar"])]
  end

  test "lexing short numeric options" do
    assert matches Lexer.tokenize("-f 123"), [types([:option, :string, :integer]),
                                              text(["-", "f", "123"])]
    assert matches Lexer.tokenize("-f 123.33"), [types([:option, :string, :float]),
                                                 text(["-", "f", "123.33"])]
  end

  test "lexing short string-like options" do
    assert matches Lexer.tokenize("-f abc"), [types([:option, :string, :string]),
                                              text(["-", "f", "abc"])]
    assert matches Lexer.tokenize("-f \"foo@bar\""), [types([:option, :string, :quoted_string]),
                                                      text(["-", "f", "foo@bar"])]
    assert matches Lexer.tokenize("-f 'foo bar'"), [types([:option, :string, :quoted_string]),
                                                       text(["-", "f", "foo bar"])]
    assert matches Lexer.tokenize("-f test:test"), [types([:option, :string, :string, :colon, :string]),
                                                    text(["-", "f", "test", ":", "test"])]
  end

  test "lexing short variable options" do
    assert matches Lexer.tokenize("-f $bar"), [types([:option, :string, :variable]),
                                                    text(["-", "f", "bar"])]

  end

  test "lexing short options with assigned numeric values" do
    assert matches Lexer.tokenize("-f=123"), [types([:option, :string, :equals, :integer]),
                                              text(["-", "f", "=", "123"])]
    assert matches Lexer.tokenize("-f=123.33"), [types([:option, :string, :equals, :float]),
                                                 text(["-", "f", "=", "123.33"])]
  end

  test "lexing short options with assigned string-like values" do
    assert matches Lexer.tokenize("-f=abc"), [types([:option, :string, :equals, :string]),
                                              text(["-", "f", "=", "abc"])]
    assert matches Lexer.tokenize("-f=\"foo@bar\""), [types([:option, :string, :equals, :quoted_string]),
                                                      text(["-", "f", "=", "foo@bar"])]
    assert matches Lexer.tokenize("-f='foo bar'"), [types([:option, :string, :equals, :quoted_string]),
                                                       text(["-", "f", "=", "foo bar"])]
    assert matches Lexer.tokenize("-f=test:test"), [types([:option, :string, :equals, :string, :colon, :string]),
                                                    text(["-", "f", "=", "test", ":", "test"])]
  end

  test "lexing short options with assigned variable values" do
    assert matches Lexer.tokenize("-f=$bar"), [types([:option, :string, :equals, :variable]),
                                                    text(["-", "f", "=", "bar"])]
  end

  test "lexing short numeric optvars" do
    assert matches Lexer.tokenize("-$f 123"), [types([:option, :variable, :integer]),
                                              text(["-", "f", "123"])]
    assert matches Lexer.tokenize("-$f 123.33"), [types([:option, :variable, :float]),
                                                  text(["-", "f", "123.33"])]
  end

  test "lexing short string-like optvars" do
    assert matches Lexer.tokenize("-$f abc"), [types([:option, :variable, :string]),
                                              text(["-", "f", "abc"])]
    assert matches Lexer.tokenize("-$f \"foo@bar\""), [types([:option, :variable, :quoted_string]),
                                                      text(["-", "f", "foo@bar"])]
    assert matches Lexer.tokenize("-$f 'foo bar'"), [types([:option, :variable, :quoted_string]),
                                                       text(["-", "f", "foo bar"])]
    assert matches Lexer.tokenize("-$f test:test"), [types([:option, :variable, :string, :colon, :string]),
                                                       text(["-", "f", "test", ":", "test"])]
  end

  test "lexing short variable optvars" do
    assert matches Lexer.tokenize("-$f $bar"), [types([:option, :variable, :variable]),
                                                text(["-", "f", "bar"])]
  end

  test "lexing short optvars with assigned numeric values" do
    assert matches Lexer.tokenize("-$f=123"), [types([:option, :variable, :equals, :integer]),
                                               text(["-", "f", "=", "123"])]
    assert matches Lexer.tokenize("-$f=123.33"), [types([:option, :variable, :equals, :float]),
                                                  text(["-", "f", "=", "123.33"])]
  end

  test "lexing short optvars with assigned string-like values" do
    assert matches Lexer.tokenize("-$f=abc"), [types([:option, :variable, :equals, :string]),
                                              text(["-", "f", "=", "abc"])]
    assert matches Lexer.tokenize("-$f=\"foo@bar\""), [types([:option, :variable, :equals, :quoted_string]),
                                                      text(["-", "f", "=", "foo@bar"])]
    assert matches Lexer.tokenize("-$f='foo bar'"), [types([:option, :variable, :equals, :quoted_string]),
                                                       text(["-", "f", "=", "foo bar"])]
    assert matches Lexer.tokenize("-$f=test:test"), [types([:option, :variable, :equals, :string, :colon, :string]),
                                                       text(["-", "f", "=", "test", ":", "test"])]
  end

  test "lexing short optvars with assigned variable value" do
    assert matches Lexer.tokenize("-$f=$bar"), [types([:option, :variable, :equals, :variable]),
                                                text(["-", "f", "=", "bar"])]
  end

  test "lexing correct json" do
    assert matches Lexer.tokenize("{{\"abc\": [1,2,1.05,\"foo\"]}}"), [types(:json),
                                                                       text("{\"abc\":[1,2,1.05,\"foo\"]}")]
  end

  test "lexing incorrect json" do
    {:error, _} = Lexer.tokenize("{{\"abc}}")
  end

  test "lexing single-quoted strings" do
    assert matches Lexer.tokenize("'this is a test'"), [types(:quoted_string), text("this is a test")]
  end

  test "lexing double-quoted strings" do
    assert matches Lexer.tokenize("\"this is a test\""), [types(:quoted_string), text("this is a test")]
  end

  test "lexing mixed quotes" do
    assert matches Lexer.tokenize("'\"this is a test\"'"), [types(:quoted_string), text("\"this is a test\"")]
    assert matches Lexer.tokenize("\"'this is a test'\""), [types(:quoted_string), text("'this is a test'")]
  end

  test "lexing escaped quotes" do
    assert matches Lexer.tokenize("\"this is a \\\"test\\\"\""), [types(:quoted_string), text("this is a \"test\"")]
    assert matches Lexer.tokenize("'this is a \\'test\\''"), [types(:quoted_string), text("this is a 'test'")]
  end

  test "lexing quoted terms returns strings" do
    assert matches Lexer.tokenize("\"123\""), [types([:quoted_string]), text("123")]
    assert matches Lexer.tokenize("\"0.05\""), [types([:quoted_string]), text("0.05")]
    assert matches Lexer.tokenize("'123'"), [types([:quoted_string]), text("123")]
    assert matches Lexer.tokenize("'$abc_def'"), [types([:quoted_string]), text("$abc_def")]
    assert matches Lexer.tokenize("'$ab3_Def'"), [types([:quoted_string]), text("$ab3_Def")]
  end

  test "single-quoted terms remain separate" do
    assert matches Lexer.tokenize("'abc' 'def' '1231'"), [types([:quoted_string, :quoted_string, :quoted_string]),
                                                          text(["abc", "def", "1231"])]
    assert matches Lexer.tokenize("'abc''def''1231'"), [types([:quoted_string, :quoted_string, :quoted_string]),
                                                        text(["abc", "def", "1231"])]
  end

  test "double-quoted terms remain separate" do
    assert matches Lexer.tokenize("\"abc\" \"def\" \"1231\""), [types([:quoted_string, :quoted_string, :quoted_string]),
                                                                text(["abc", "def", "1231"])]
    assert matches Lexer.tokenize("\"abc\"\"def\"\"1231\""), [types([:quoted_string, :quoted_string, :quoted_string]),
                                                              text(["abc", "def", "1231"])]
  end

  test "embedded newlines are lexed" do
    assert matches Lexer.tokenize("123\n456\n\nabc"), [types([:integer, :integer, :string])]
  end

  test "unterminated string causes error" do
    {:error, {:unexpected_input, 10, _}} = Lexer.tokenize("ec2-find \"test-db")
  end

end
