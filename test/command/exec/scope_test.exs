defmodule Exec.ScopeTest do

  use ExUnit.Case

  alias Piper.Command.Scoped
  alias Piper.Command.Bind.Scope

  defmacrop verify_scope(scope, values) do
    quote do
      for {key, value} <- unquote(values) do
        value = case value do
                  {:error, value} ->
                    value
                  value ->
                    {:ok, value}
                end
        assert value == Scoped.lookup(unquote(scope), key)
      end
    end
  end

  test "key lookup in a single scope" do
    scope = Scope.from_map(%{"foo" => 1, "bar" => "baz"})
    verify_scope(scope, [{"foo", 1},
                         {"bar", "baz"},
                         {"quux", {:error, {:not_found, "quux"}}}])
  end

  test "key lookup with two level scope" do
    scope1 = Scope.from_map(%{"foo" => 1})
    scope2 = Scope.from_map(%{"bar" => "baz"})
    {:ok, scope} = Scoped.set_parent(scope1, scope2)
    verify_scope(scope, [{"foo", 1},
                         {"bar", "baz"},
                         {"quux", {:error, {:not_found, "quux"}}}])
  end

  test "\"lower\" scopes override higher scopes" do
    scope1 = Scope.from_map(%{"foo" => 1, "bar" => "baz"})
    scope2 = Scope.from_map(%{"bar" => "quux"})
    {:ok, scope} = Scoped.set_parent(scope2, scope1)
    verify_scope(scope, [{"foo", 1}, {"bar", "quux"}])
  end

end
