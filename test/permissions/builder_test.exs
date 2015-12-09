defmodule Piper.Permissions.BuilderTest do

  alias Piper.Permissions.Parser
  require Piper.Permissions.RuleBuilder
  import Piper.Permissions.RuleBuilder, only: [add_input_criteria: 2,
                                               add_permission_criteria: 2]
  alias Piper.Permissions.RuleBuilder

  use ExUnit.Case

  test "construct valid permission rule" do
    rule = RuleBuilder.new("foo:bar")
    |> add_input_criteria(arg: 0, op: :equiv, value: 1)
    |> add_input_criteria(and: [arg: 1, op: :gt, value: 5])
    |> add_permission_criteria(any: ["foo:read", "foo:write"])
    |> RuleBuilder.finish
    assert rule == "when command is foo:bar with arg[0] == 1 and arg[1] > 5 must have any in [foo:read, foo:write]"
    assert {:ok, ast, _} = Parser.parse(rule)
    assert "#{ast}" == rule
  end

  test "construct valid permission rule with multiple permission criteria" do
    rule = RuleBuilder.new("foo:bar")
    |> add_input_criteria(option: "action", op: :equiv, value: "grant")
    |> add_permission_criteria(all: ["foo:write", "site:ops"])
    |> add_permission_criteria(or: [any: ["site:admin", "site:management"]])
    |> RuleBuilder.finish
    assert rule == "when command is foo:bar with option[action] == \"grant\" must have " <>
      "all in [foo:write, site:ops] or any in [site:admin, site:management]"
    assert {:ok, ast, _} = Parser.parse(rule)
    assert "#{ast}" == rule
  end
end
