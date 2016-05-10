alias Piper.Command.Ast.Util

defmodule Piper.Command.Ast.Integer do

  defstruct [line: nil, col: nil, value: nil]

  def new({:integer, meta, value}) do
    {line, col} = Util.position(meta)
    %__MODULE__{line: line, col: col, value: String.to_integer(String.Chars.to_string(value))}
  end

end

defmodule Piper.Command.Ast.Float do

  defstruct [line: nil, col: nil, value: nil]

  def new({:float, meta, value}) do
    {line, col} = Util.position(meta)
    %__MODULE__{line: line, col: col, value: String.to_float(String.Chars.to_string(value))}
  end

end

defmodule Piper.Command.Ast.Bool do

  defstruct [line: nil, col: nil, value: nil]

  def new({:bool, meta, value}) do
    {line, col} = Util.position(meta)
    %__MODULE__{line: line, col: col, value: convert(value)}
  end

  def new(line, col, value) do
    new({:bool, {line, col}, value})
  end

  defp convert('true') do
    true
  end
  defp convert('false') do
    false
  end

end

defmodule Piper.Command.Ast.String do

  defstruct [line: nil, col: nil, value: nil, enclosed_by: nil]

  def new({:string, meta, value}) do
    {line, col} = Util.position(meta)
    set_enclosed_by(%__MODULE__{line: line, col: col, value: String.Chars.to_string(value)})
  end
  def new(value) when is_binary(value) do
    set_enclosed_by(%__MODULE__{line: 0, col: 0, value: value})
  end
  def new({line, col}, value) when is_binary(value) do
    set_enclosed_by(%__MODULE__{line: line, col: col, value: value})
  end

  defp set_enclosed_by(%__MODULE__{value: value}=str) do
    cond do
      String.match?(value, ~r/"(\\\^.|\\.|[^"])*"/) ->
        %{str | value: String.slice(value, 1, String.length(value) - 2), enclosed_by: "\""}
      String.match?(value, ~r/'(\\\^.|\\.|[^'])*'/) ->
        %{str | value: String.slice(value, 1, String.length(value) - 2), enclosed_by: "'"}
      true ->
        str
    end
  end
end

defmodule Piper.Command.Ast.Emoji do

  defstruct [line: nil, col: nil, value: nil]

  def new({:string, meta, value}) do
    {line, col} = Util.position(meta)
    %__MODULE__{line: line, col: col, value: String.Chars.to_string(value)}
  end

end
