defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Scoped
  alias Piper.Command.BindError

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
              handle_error(error, var)
          end
        end
      error ->
        handle_error(error, var)
    end
  end

  defp eval_ops([], value), do: {:ok, value}
  defp eval_ops([{:index, index}|t], value) do
    case Enum.at(value, index, :out_of_bounds) do
      :out_of_bounds ->
        {:out_of_bounds, index}
      value ->
        eval_ops(t, value)
    end
  end
  defp eval_ops([{:key, key}|t], value) do
    case Map.get(value, key, :not_found) do
      :not_found ->
        {:not_found, key}
      value ->
        eval_ops(t, value)
    end
  end

  defp handle_error({:out_of_bounds, index}, var) do
    throw BindError.new("#{var}", {:out_of_bounds, index})
  end
  defp handle_error({:not_found, key}, var) do
    throw BindError.new("#{var}", {:missing_key, key})
  end

end
