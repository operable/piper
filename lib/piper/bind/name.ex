defimpl Piper.Bindable, for: Piper.Ast.Name do

  def resolve(_name, scope) do
    {:ok, scope}
  end

  def bind(%Piper.Ast.Name{name: name}, scope) do
    {:ok, name, scope}
  end

end
