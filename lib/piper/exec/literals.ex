defimpl Piper.Executable, for: [Piper.Ast.Integer,
                                 Piper.Ast.Float,
                                 Piper.Ast.String] do

  def resolve(_exec, scope) do
    {:ok, scope}
  end

  def execute(literal, _scope) do
    {:ok, Map.merge(%{}, literal)}
  end
end
