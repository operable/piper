defimpl Piper.Command.Bindable, for: [Piper.Command.Ast.Integer,
                              Piper.Command.Ast.Float,
                              Piper.Command.Ast.Bool] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(literal, scope) do
    {:ok, literal.value, scope}
  end

end

defimpl Piper.Command.Bindable, for: [Piper.Command.Ast.String] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(literal, scope) do
    {:ok, literal.value, scope}
  end

end

defimpl Piper.Command.Bindable, for: [Piper.Command.Ast.Json] do

  alias Piper.Command.Ast

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(%Ast.Json{value: value}, scope) when is_binary(value) do
    {:ok, Poison.decode!(value), scope}
  end
  def bind(%Ast.Json{value: value}, scope) do
    {:ok, value, scope}
  end

end
