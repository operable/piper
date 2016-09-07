defmodule Exec.ScopeTest do

  use ExUnit.Case

  alias Piper.Common.Scope.Scoped
  alias Piper.Common.Scope

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

  test "erasing values" do
    scope1 = Scope.from_map(%{"foo" => 1})
    scope1 = Scoped.erase(scope1, "foo")
    assert Scoped.lookup(scope1, "foo") == {:not_found, "foo"}
  end

  test "erasing values honors scope boundaries" do
    scope1 = Scope.from_map(%{"abc" => 123})
    scope2 = Scope.from_map(%{"def" => 456})
    {:ok, scope} = Scoped.set_parent(scope2, scope1)
    assert Scoped.lookup(scope, "abc") == {:ok, 123}
    assert Scoped.lookup(scope, "def") == {:ok, 456}
    scope = Scoped.erase(scope, "def")
    assert Scoped.lookup(scope, "def") == {:not_found, "def"}
    scope = Scoped.erase(scope, "abc")
    assert Scoped.lookup(scope, "abc") == {:ok, 123}
  end

end
