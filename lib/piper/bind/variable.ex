defimpl Piper.Bindable, for: Piper.Ast.Variable do

  alias Piper.Scoped
  alias Piper.Ast

  def bind(var, scope) do
    case Scoped.lookup_variable(scope, var) do
      {:ok, value} ->
        {:ok, build_type(var, value), scope}
      error ->
        error
    end
  end

  def resolve(%Ast.Variable{name: name, index: nil}=var, scope) do
    case Scoped.lookup(scope, name) do
      {:ok, value} ->
        Scoped.bind_variable(scope, var, value)
      error ->
        error
    end
  end
  def resolve(%Ast.Variable{name: name, index: index}=var, scope) do
    case Scoped.lookup(scope, name) do
      {:ok, value} ->
        case fetch_index(value, index, scope) do
          {:ok, indexed_value} ->
            Scoped.bind_variable(scope, var, indexed_value)
          error ->
            error
        end
      error ->
        error
    end
  end

  defp build_type(var, value) when is_atom(value) do
    Ast.Bool.new(var.line, var.col, value)
  end
  defp build_type(var, value) when is_integer(value) do
    Ast.Integer.new(var.line, var.col, value)
  end
  defp build_type(var, value) when is_float(value) do
    Ast.Float.new(var.line, var.col, value)
  end
  defp build_type(var, value) when is_binary(value) do
    Ast.String.new(var.line, var.col, value)
  end

  defp fetch_index(_value, %Ast.Integer{value: index}, _scope) when index < 0 do
    {:error, {:array_bounds, index}}
  end
  defp fetch_index(value, %Ast.Integer{value: index}, _scope) when is_list(value) do
    read_at_index(value, index)
  end
  defp fetch_index(value, %Ast.Variable{}=index_var, scope) when is_list(value) do
    case Piper.Bindable.resolve(index_var, scope) do
      {:ok, idx} when is_integer(idx) ->
        read_at_index(value, idx)
      {:ok, idx} ->
        {:error, {:bad_array_index, idx}}
      error ->
        error
    end
  end
  defp fetch_index(value, _index, _scope) when is_list(value) do
    {:error, :bad_array_index_type}
  end
  defp fetch_index(value, index_value, _scope) when is_map(value) do
    index = Map.get(index_value, :value)
    case Map.get(value, index) do
      nil ->
        {:error, {:not_found, index}}
      iv ->
        {:ok, iv}
    end
  end

  defp read_at_index(value, index) do
    actual_index = max(0, index - 1)
    case actual_index < length(value) do
      true ->
        {:ok, Enum.at(value, actual_index)}
      false ->
        {:error, {:array_bounds, index}}
    end
  end

end
