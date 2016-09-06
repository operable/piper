defmodule Piper.Common.Scope do

  alias Piper.Common.Bindable
  alias Piper.Common.BindError

  defstruct [values: %{}, bindings: %{}, parent: nil]

  def from_map(values) do
    %__MODULE__{values: values}
  end

  def empty_scope() do
    %__MODULE__{}
  end

  def bind(ast, %__MODULE__{}=scope) do
    try do
      {:ok, scope} = Bindable.resolve(ast, scope)
      Bindable.bind(ast, scope)
    catch
      error -> BindError.format_error(error)
    end
  end

end

defimpl Piper.Common.Scope.Scoped, for: Piper.Common.Scope do

  alias Piper.Common.Scope

  def set_parent(%Scope{parent: nil}=scope, parent) do
    {:ok, %{scope | parent: parent}}
  end
  def set_parent(%Scope{}, _parent) do
    {:error, :have_parent}
  end

  def lookup(%Scope{values: values, parent: nil}, name) do
    case Map.get(values, name) do
      nil ->
        {:not_found, name}
      value ->
        {:ok, value}
    end
  end
  def lookup(%Scope{values: values, parent: parent}, name) do
    case Map.get(values, name) do
      nil ->
        Piper.Common.Scope.Scoped.lookup(parent, name)
      value ->
        {:ok, value}
    end
  end

  def set(%Scope{values: values}=scope, name, value) do
    case lookup(scope, name) do
      {:not_found, _} ->
        {:ok, %{scope | values: Map.put(values, name, value)}}
      {:ok, _} ->
        {:error, :already_stored}
    end
  end

  def update(%Scope{values: values}=scope, name, value) do
    case lookup(scope, name) do
      {:ok, _} ->
        {:ok, %{scope | values: Map.put(values, name, value)}}
      error ->
        error
    end
  end

  def bind_variable(%Scope{bindings: bindings}=scope, var, value) do
    bindings = Map.put_new(bindings, to_string(var), value)
    {:ok, %{scope | bindings: bindings}}
  end

  def lookup_variable(%Scope{bindings: bindings}, var) do
    {:ok, Map.get(bindings, to_string(var))}
  end

end
