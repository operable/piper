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

defmodule Piper.Ast.String do

  defstruct [:line, :col, :value, :raw]

  alias Piper.Util.Token

  def new(%Token{line: line, col: col, text: text, raw: raw}) do
    %__MODULE__{line: line, col: col, value: text, raw: raw}
  end

  def new(line, col, text) do
    %__MODULE__{line: line, col: col, value: text, raw: text}
  end
end
