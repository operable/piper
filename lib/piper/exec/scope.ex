defmodule Piper.Exec.Scope do
  defstruct [values: %{}, bindings: %{}, parent: nil]

  def from_map(values) do
    %__MODULE__{values: values}
  end

end

defimpl Piper.Scoped, for: Piper.Exec.Scope do

  alias Piper.Exec.Scope

  def set_parent(%Scope{parent: nil}=scope, parent) do
    {:ok, %{scope | parent: parent}}
  end
  def set_parent(%Scope{}) do
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
        Piper.Scoped.lookup(parent, name)
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
        {:error, :already_bound}
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
