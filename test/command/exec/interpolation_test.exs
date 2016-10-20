defmodule Bind.InterpolationTest do

  use ExUnit.Case

  alias Piper.Common.Scope

  use Piper.Test.BindHelpers

  test "basic string interpolation works" do
    scope = Scope.from_map(%{"value" => "a test"})
    {:ok, ast} = parse_and_bind2("echo \"this is ${value}\"", scope)
    assert "#{ast}" == "echo this is a test"
  end

  test "string interpolation with varops works" do
    scope = Scope.from_map(%{"users" => [%{"userid" => 100, "username" => "bob"},
                                         %{"userid" => 101, "username" => "linda"}]})
    {:ok, ast} = parse_and_bind2("echo \"${users[0].username} has id ${users[0].userid}\"", scope)
    assert "#{ast}" == "echo bob has id 100"
  end

end
