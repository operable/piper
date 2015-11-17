defimpl Piper.Executable, for: [Piper.Ast.Integer,
                                 Piper.Ast.Float,
                                 Piper.Ast.String] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def prepare(literal, scope) do
    {:ok, Map.merge(%{}, literal), scope}
  end

end
