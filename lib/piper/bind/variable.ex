defimpl Piper.Bindable, for: Piper.Ast.Variable do

  alias Piper.Scoped
  alias Piper.Ast

  def bind(var, scope) do
    case Scoped.lookup_variable(scope, var) do
      {:ok, value} ->
        {:ok, value, scope}
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

end
