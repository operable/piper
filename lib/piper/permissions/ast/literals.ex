defmodule Piper.Permissions.Ast.String do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "string"}, :line, :col, :value, :quotes]

  def new({:string, {line, col}, text}) do
    text = String.Chars.to_string(text)
    %__MODULE__{line: line, col: col, value: text}
  end
  def new({:name, {line, col}, text}) do
    text = String.Chars.to_string(text)
    %__MODULE__{line: line, col: col, value: text}
  end
  def new({:dqstring, {line, col}, text}) do
    text = String.Chars.to_string(text)
    %__MODULE__{line: line, col: col, value: text, quotes: "\""}
  end
  def new({:sqstring, {line, col}, text}) do
    text = String.Chars.to_string(text)
    %__MODULE__{line: line, col: col, value: text, quotes: "'"}
  end
  def new(%__MODULE__{line: line, col: col, value: value1,
                      quotes: quotes1}, {:colon, _, _},
          %__MODULE__{value: value2, quotes: quotes2}) do
    quotes = cond do
      quotes1 != nil ->
        quotes1
      quotes2 != nil ->
        quotes2
      true ->
        nil
    end
    %__MODULE__{line: line, col: col, value: "#{value1}:#{value2}", quotes: quotes}
  end
end

defmodule Piper.Permissions.Ast.Integer do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "integer"}, :line, :col, :value]

  def new({:integer, {line, col}, value}) do
    %__MODULE__{line: line, col: col, value: value}
  end

end

defmodule Piper.Permissions.Ast.Float do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "float"}, :line, :col, :value]

  def new({:float, {line, col}, value}) do
    %__MODULE__{line: line, col: col, value: value}
  end

end

defmodule Piper.Permissions.Ast.Bool do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "bool"}, :line, :col, :value]

  def new({:boolean, {line, col}, value}) do
    %__MODULE__{line: line, col: col, value: value}
  end

end

defmodule Piper.Permissions.Ast.List do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "array"}, :line, :col, :values]

  def new({:lbracket, {line, col}, _}, values) do
    %__MODULE__{line: line, col: col, values: values}
  end

end

defmodule Piper.Permissions.Ast.Regex do

  defstruct [{:'$ast$', "regex"}, :line, :col, :value]

  def new({:regex, {line, col}, value}) do
    value = String.Chars.to_string(value)
    %__MODULE__{line: line, col: col, value: Regex.compile!(value)}
  end

end

defmodule Piper.Permissions.Ast.Arg do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "arg"}, :line, :col, :index]

  def new({:arg, {line, col}, nil}, type) when type in [:any, :all] do
    %__MODULE__{line: line, col: col, index: type}
  end
  def new({:arg, {line, col}, index}, _type) do
    %__MODULE__{line: line, col: col, index: index}
  end

  def build(index) when index in [:any, :all] do
    %__MODULE__{index: index}
  end
  def build(index) when index > -1 do
    %__MODULE__{index: index}
  end

end

defmodule Piper.Permissions.Ast.Option do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "option"}, :line, :col, :name]

  def new({:option, {line, col}, _}, type) when type in [:any, :all] do
    %__MODULE__{line: line, col: col, name: type}
  end
  def new({:option, {line, col}, _}, {:string, _, value}) do
    value = String.Chars.to_string(value)
    %__MODULE__{line: line, col: col, name: value}
  end
  def new({:option, {line, col}, _}, {:name, _, value}) do
    value = String.Chars.to_string(value)
    %__MODULE__{line: line, col: col, name: value}
  end


  def build(type) when type in [:any, :all] do
    %__MODULE__{name: type}
  end
  def build(name) when is_binary(name) do
    %__MODULE__{name: name}
  end

end
