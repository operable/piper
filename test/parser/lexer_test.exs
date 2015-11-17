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
end
