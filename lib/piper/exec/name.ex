defimpl Piper.Executable, for: Piper.Ast.Name do

  def resolve(_exec, scope) do
    {:ok, scope}
  end

  def execute(%Piper.Ast.Name{line: line, col: col, name: name}=name, _scope) do
    {:ok, %Piper.Ast.Name{line: line, col: col, name: name}}
  end

end
