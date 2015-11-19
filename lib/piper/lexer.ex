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
  # JSON literal
  token :json, pattern: ~r/\A{{([[:graph:]]| )+}}/, post: :clean_json
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
  # Non-indexed variables eg: $hostname
  token :variable, pattern: ~r/\A(\$)([a-zA-Z0-9_\$])+/, post: :clean_variable
  # Boolean values
  token :bool, pattern: ~r/\A(true|TRUE|\#t|false|FALSE|\#f)/
  # Command name
  token :name, pattern: ~r/\A([a-z])+([a-zA-Z0-9_\-\*])+(?:\s)*/
  # Option name
  token :option, pattern: ~r/\A\-\-[a-zA-Z0-9_]([a-zA-Z0-9_-])+/, post: :clean_option
  token :option, pattern: ~r/\A\-[a-zA-Z0-9_]([a-zA-Z0-9-_])*/, post: :clean_option
  # Variable as option name
  token :optvar, pattern: ~r/\A--\$([a-zA-Z0-9_])+/, post: :clean_optvar
  token :optvar, pattern: ~r/\A-\$([a-zA-Z0-9_])+/, post: :clean_optvar
  token :float, pattern: ~r/\A([0-9])+\.([0-9])+(?:\s)*/
  token :integer, pattern: ~r/\A([0-9])+/
  # Tokenize quoted strings as whole strings
  token :string, pattern: ~r/\A'(\\\\A.|\\.|[^'])*'/, post: :clean_string
  # Tokenize double-quoted strings as whole strings
  token :string, pattern: ~r/\A"(\\\\A.|\\.|[^"])*"/, post: :clean_string
  # Tokenize anything else not starting with one or two dashes as a
  # command argument
  token :string, pattern: ~r/\A([[:graph:]])+/, post: :clean_arg

  def clean_string(text) do
    text = Regex.replace(~r/\A(\"|\')/, text, "")
    text = Regex.replace(~r/(\"|\')\z/, text, "")
    text = Regex.replace(~r/(\\\")/, text, "\"")
    text = Regex.replace(~r/(\\\')/, text, "'")
    text
  end

  def clean_option(text) do
    Regex.replace(~r/\A(--|-)/, text, "")
  end

  def clean_variable(text) do
    Regex.replace(~r/\A\$/, text, "")
  end

  def clean_optvar(text) do
    text
    |> clean_option
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
        json = "{" <> json <> "}"
        case Poison.decode(json) do
          {:ok, json} ->
            Poison.encode!(json)
          {:error, _} ->
            :stop
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
