defimpl Piper.Command.Bindable, for: [Piper.Command.Ast2.Integer,
                                      Piper.Command.Ast2.Float,
                                      Piper.Command.Ast2.Bool,
                                      Piper.Command.Ast2.String] do

  def resolve(_literal, scope) do
    {:ok, scope}
  end

  def bind(literal, scope) do
    {:ok, literal.value, scope}
  end

end
