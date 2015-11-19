defimpl Piper.Bindable, for: [Piper.Ast.Integer,
                              Piper.Ast.Float,
                              Piper.Ast.Bool] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(literal, scope) do
    {:ok, literal.value, scope}
  end

end

defimpl Piper.Bindable, for: [Piper.Ast.String] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(literal, scope) do
    if literal.raw != nil do
      {:ok, literal.raw, scope}
    else
      {:ok, literal.value, scope}
    end
  end

end
