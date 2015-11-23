defmodule Piper.Lexer do

  use Piper.Util.LexerGenerator

  # Tokens patterns are tried in the order they appear.
  # Reordering token patterns will very likely change
  # overall parse results.

  # Skip whitespace
  token :skip, pattern: ~r/\A( )/
  # Skip line
  token :skip_line, pattern: ~r/\A\r\n/
  token :skip_line, pattern: ~r/\A\n/
  # Output-to-input linked pipeline
  token :pipe, pattern: ~r/\A(\|)/
  # Continue only if first command was successful
  token :iff,  pattern: ~r/\A(&&)/
  # Redirect output
  token :redir, pattern: ~r/\A(>)/
  token :equals, pattern: ~r/\A=/
  token :lbracket, pattern: ~r/\A\[/
  token :rbracket, pattern: ~r/\A\]/
  token :colon, pattern: ~r/\A\:/
  # Variable as option name
  token :option, pattern: ~r/\A\-\-/
  token :option, pattern: ~r/\A\-/
  # JSON literal
  token :json, pattern: ~r/\A{{([[:graph:]]| )+}}/, post: :clean_json
  # Tokenize quoted strings as whole strings
  token :quoted_string, pattern: ~r/\A'(\\\\A.|\\.|[^'])*'(?:\s|\z)*/, post: :clean_quoted_string
  # Tokenize double-quoted strings as whole strings
  token :quoted_string, pattern: ~r/\A"(\\\\A.|\\.|[^"])*"(?:\s|\z)*/, post: :clean_quoted_string
  # Non-indexed variables eg: $hostname
  token :variable, pattern: ~r/\A(\$)([a-zA-Z0-9_\$])+/, post: :clean_variable
  # Boolean values
  token :bool, pattern: ~r/\A(true|TRUE|\#t|false|FALSE|\#f)/
  token :float, pattern: ~r/\A([0-9])+\.([0-9])+/
  token :integer, pattern: ~r/\A([0-9])+/
  token :string, pattern: ~r/\A([a-zA-Z0-9_\-])+/
  token :string, pattern: ~r/\A([[:graph:]])+(?:\s|\z)*/, post: :clean_string

  def clean_quoted_string(text) do
    text = Regex.replace(~r/\A(\"|\')/, text, "")
    text = Regex.replace(~r/(\"|\')\z/, text, "")
    text = Regex.replace(~r/(\\\")/, text, "\"")
    text = Regex.replace(~r/(\\\')/, text, "'")
    text
  end

  def clean_string(text) do
    if String.starts_with?(text, "\"") or String.starts_with?(text, "'") do
      :stop
    else
      text
    end
  end

  def clean_variable(text) do
    Regex.replace(~r/\A\$/, text, "")
  end

  def clean_optvar(text) do
    Regex.replace(~r/\A(--|-)/, text, "")
    |> clean_variable
  end

  def clean_json(text) do
    json = String.slice(text, 2, String.length(text) - 4)
    case Poison.decode(json) do
      {:ok, json} ->
        Poison.encode!(json)
      {:error, _} ->
        # Maybe the user forgot to add additional braces
        # for maps contained within the double braces we required.
        # We'll add them back and see if that allows the JSON to
        # successfully parse.
        json1 = "{" <> json <> "}"
        case Poison.decode(json1) do
          {:ok, json1} ->
            Poison.encode!(json1)
          {:error, _} ->
            # Adding braces didn't work so maybe the user typed a list
            # We'll add brackets and see if that allows the JSON to parse.
            json2 = "[" <> json <> "]"
            case Poison.decode(json2) do
              {:ok, json2} ->
                Poison.encode!(json2)
              {:error, _} ->
                :stop
            end
        end
    end
  end

  def clean_arg(text) do
    if String.starts_with?(text, "\"") do
      :error
    else
      if String.starts_with?(text, "'") do
        :error
      else
        text
      end
    end
  end

end
