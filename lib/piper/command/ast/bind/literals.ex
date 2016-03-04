defimpl Piper.Command.Bindable, for: [Piper.Command.Ast.Integer,
                                      Piper.Command.Ast.Float,
                                      Piper.Command.Ast.Bool,
                                      Piper.Command.Ast.String] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(literal, scope) do
    {:ok, literal.value, scope}
  end

end
