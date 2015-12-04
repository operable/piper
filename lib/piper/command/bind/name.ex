defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Name do

  def resolve(_name, scope) do
    {:ok, scope}
  end

  def bind(%Piper.Command.Ast.Name{name: name}, scope) do
    {:ok, name, scope}
  end

end
