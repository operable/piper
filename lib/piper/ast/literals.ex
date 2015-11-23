defmodule Piper.Ast.Integer do

  use Piper.Util.TokenWrapper

  defwrapper [value: :value, converter: :convert, token_type: :integer]

  def new(line, col, value) do
    %__MODULE__{line: line, col: col, value: value}
  end

  def convert(%__MODULE__{value: value}=literal) when is_binary(value) do
    try do
      %{literal | value: String.to_integer(value)}
    rescue
      ArgumentError ->
        {:error, "Failed to convert '#{value}' to an integer"}
    end
  end

end

defmodule Piper.Ast.Float do

  use Piper.Util.TokenWrapper

  defwrapper [value: :value, converter: :convert, token_type: :float]

  def new(line, col, value) do
    %__MODULE__{line: line, col: col, value: value}
  end

  def convert(%__MODULE__{value: value}=literal) when is_binary(value) do
    try do
      %{literal | value: String.to_float(value)}
    rescue
      ArgumentError ->
        {:error, "Failed to convert '#{value}' to a float"}
    end
  end

end

defmodule Piper.Ast.Bool do

  use Piper.Util.TokenWrapper

  defwrapper [value: :value, converter: :convert, token_type: :bool]

  def new(line, col, value) when value in [:true, :false] do
    %__MODULE__{line: line, col: col, value: value}
  end

  def convert(%__MODULE__{value: value}=literal) do
    %{literal | value: convert(String.downcase(value))}
  end
  def convert("true") do
    true
  end
  def convert("#t") do
    true
  end
  def convert("false") do
    false
  end
  def convert("#f") do
    false
  end
end

defmodule Piper.Ast.String do

  defstruct [:line, :col, :value]

  alias Piper.Util.Token

  def new(%Token{line: line, col: col, text: text}) do
    %__MODULE__{line: line, col: col, value: text}
  end

  def new(line, col, text) do
    %__MODULE__{line: line, col: col, value: text}
  end
end

defmodule Piper.Ast.Json do

  defstruct [:line, :col, :raw, :value]

  alias Piper.Util.Token

  def new(%Token{line: line, col: col, text: text, raw: raw}) do
    %__MODULE__{line: line, col: col, value: text, raw: raw}
  end

  def new(line, col, value) do
    convert(%__MODULE__{line: line, col: col, value: value})
  end

  def convert(%__MODULE__{value: value}=node) when is_binary(value) do
    raw = "{{" <> value <> "}}"
    %{node | value: Poison.decode!(value), raw: raw}
  end
  def convert(%__MODULE__{value: value}=node) do
    json = Posion.encode!(value)
    %{node | value: json, raw: "{{" <> json <> "}}"}
  end

end
