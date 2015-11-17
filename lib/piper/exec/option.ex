defimpl Piper.Executable, for: Piper.Ast.Option do

  alias Piper.Ast

  def resolve(%Ast.Option{flag: flag, value: value}, scope) do
    case resolve_value(flag, scope) do
      {:ok, scope} ->
        case resolve_value(value, scope) do
          {:ok, scope} ->
            {:ok, scope}
          error ->
            error
        end
      error ->
        error
    end
  end
  def execute(%Ast.Option{flag: flag, value: value}=option, scope) do
    case execute_value(flag, scope) do
      {:ok, flag} ->
        case execute_value(value, scope) do
          {:ok, value} ->
            {:ok, %{option | flag: flag, value: value}}
          error ->
            error
        end
      error ->
        error
    end
  end

  defp resolve_value(nil, scope) do
    {:ok, scope}
  end
  defp resolve_value(v, scope) when is_binary(v) do
    {:ok, scope}
  end
  defp resolve_value(value, scope) do
    Piper.Executable.resolve(value, scope)
  end

  defp execute_value(nil, _scope) do
    {:ok, nil}
  end
  defp execute_value(v, _scope) when is_binary(v) do
    {:ok, v}
  end
  defp execute_value(value, scope) do
    Piper.Executable.execute(value, scope)
  end

end
