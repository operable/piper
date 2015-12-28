defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Variable do

  alias Piper.Command.Scoped
  alias Piper.Command.Ast
  alias Piper.Command.SemanticError

  def bind(var, scope) do
    case Scoped.lookup_variable(scope, var) do
      {:ok, value} ->
        case maybe_trigger_binding_hook(var, value) do
          {:ok, updated} ->
            {:ok, updated, scope}
          error ->
            error
        end
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
  def resolve(%Ast.Variable{name: name, index: %Ast.Integer{value: index}}=var, scope) do
    case Scoped.lookup(scope, name) do
      {:ok, value} when is_list(value) ->
        case Enum.at(value, index) do
          nil ->
            {:error, {:array_bounds, index}}
          entry ->
            Scoped.bind_variable(scope, var, entry)
        end
      {:ok, _} ->
        {:error, {:bad_type, name}}
      error ->
        error
    end
  end
  def resolve(%Ast.Variable{name: name, index: %Ast.String{value: key}}=var, scope) do
    case Scoped.lookup(scope, name) do
      {:ok, value} when is_map(value) ->
        case Map.get(value, key) do
          nil ->
            {:error, {:missing_key, key}}
          entry ->
            Scoped.bind_variable(scope, var, entry)
        end
      {:ok, _} ->
        {:error, {:bad_type, name}}
      error ->
        error
    end
  end

  defp maybe_trigger_binding_hook(%Ast.Variable{binding_hook: nil}, value) do
    {:ok, value}
  end
  defp maybe_trigger_binding_hook(%Ast.Variable{binding_hook: hook}, value) do
    case hook.(value) do
      {:ok, bundle} ->
        {:ok, bundle <> ":" <> value}
      :identity ->
        {:ok, value}
      error=%SemanticError{} ->
        SemanticError.format_error(error)
    end
  end

end
