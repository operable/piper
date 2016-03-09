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
        if Enum.empty?(var.ops) do
          Scoped.bind_variable(scope, var, value)
        else
          case eval_ops(var.ops, value) do
            {:ok, value} ->
              Scoped.bind_variable(scope, var, value)
            error ->
              error
          end
        end
      error ->
        error
    end
  end

  defp eval_ops([], value), do: {:ok, value}
  defp eval_ops([{:index, index}|t], value) do
    eval_ops(t, Enum.at(value, index, :not_found))
  end
  defp eval_ops([{:key, key}|t], value) do
    eval_ops(t, Map.get(value, key, :not_found))
  end
end
