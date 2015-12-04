defmodule Piper.Command.Bind.Scope do
  defstruct [values: %{}, bindings: %{}, parent: nil]

  def from_map(values) do
    %__MODULE__{values: values}
  end

  def empty_scope() do
    %__MODULE__{}
  end

end

defimpl Piper.Command.Scoped, for: Piper.Command.Bind.Scope do

  alias Piper.Command.Bind.Scope

  def set_parent(%Scope{parent: nil}=scope, parent) do
    {:ok, %{scope | parent: parent}}
  end
  def set_parent(%Scope{}, _parent) do
    {:error, :have_parent}
  end

  def lookup(%Scope{values: values, parent: nil}, name) do
    case Map.get(values, name) do
      nil ->
        {:error, {:not_found, name}}
      value ->
        {:ok, value}
    end
  end
  def lookup(%Scope{values: values, parent: parent}, name) do
    case Map.get(values, name) do
      nil ->
        Piper.Command.Scoped.lookup(parent, name)
      value ->
        {:ok, value}
    end
  end

  def set(%Scope{values: values}=scope, name, value) do
    case lookup(scope, name) do
      {:error, :not_found} ->
        {:ok, %{scope | values: Map.put(values, name, value)}}
      {:ok, _} ->
        {:error, :already_stored}
    end
  end

  def bind_variable(%Scope{bindings: bindings}=scope, var, value) do
    key = "#{var}"
    case Map.has_key?(bindings, key) do
      true ->
        raise RuntimeError, "#{key} is already bound!"
#        {:error, {:already_bound, key}}
      false ->
        bindings = Map.put(bindings, key, value)
        {:ok, %{scope | bindings: bindings}}
    end
  end

  def lookup_variable(%Scope{bindings: bindings}, var) do
    key = "#{var}"
    case Map.get(bindings, key) do
      nil ->
        {:error, :not_found}
      value ->
        {:ok, value}
    end
  end

end
