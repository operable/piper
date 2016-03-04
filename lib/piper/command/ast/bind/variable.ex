defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Scoped

  def bind(var, scope) do
    case Scoped.lookup_variable(scope, var) do
      {:ok, value} ->
        {:ok, %{var | value: value}, scope}
      error ->
        error
    end
  end

  def resolve(var, scope) do
    case Scoped.lookup(scope, "#{var.name}") do
      {:ok, value} ->
        Scoped.bind_variable(scope, var, value)
      error ->
        error
    end
  end

end
