defimpl Piper.Bindable, for: Piper.Ast.Option do

  alias Piper.Ast

  def bind(%Ast.Option{flag: flag, value: value}=option, scope) do
    case bind_value(flag, scope) do
      {:ok, flag, scope} ->
        case bind_value(value, scope) do
          {:ok, value, scope} ->
            {:ok, %{option | flag: flag, value: value}, scope}
          error ->
            error
        end
      error ->
        error
    end
  end

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

  defp resolve_value(nil, scope) do
    {:ok, scope}
  end
  defp resolve_value(v, scope) when is_binary(v) do
    {:ok, scope}
  end
  defp resolve_value(value, scope) do
    Piper.Bindable.resolve(value, scope)
  end

  defp bind_value(nil, scope) do
    {:ok, nil, scope}
  end
  defp bind_value(v, scope) when is_binary(v) do
    {:ok, v, scope}
  end
  defp bind_value(value, scope) do
    Piper.Bindable.bind(value, scope)
  end

end
