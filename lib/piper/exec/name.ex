defimpl Piper.Executable, for: Piper.Ast.Name do

  def resolve(_name, scope) do
    {:ok, scope}
  end

  def prepare(%Piper.Ast.Name{line: line, col: col, name: name}=name, scope) do
    {:ok, %Piper.Ast.Name{line: line, col: col, name: name}, scope}
  end

end
