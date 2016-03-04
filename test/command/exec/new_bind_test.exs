defmodule Bind.NewBindTest do

  use ExUnit.Case

  alias :piper_cmd_parser, as: Parser
  alias Piper.Command.Bindable
  alias Piper.Command.Bind
  alias Piper.Command.Ast2, as: Ast

  defp link_scopes([]) do
    Bind.Scope.empty_scope()
  end
  defp link_scopes(vars) do
    make_scope_chain(Enum.reverse(vars))
  end

  defp make_scope_chain([h]) do
    Bind.Scope.from_map(h)
  end
  defp make_scope_chain([h|t]) do
    parent = make_scope_chain(t)
    scope = Bind.Scope.from_map(h)
    {:ok, scope} = Piper.Command.Scoped.set_parent(scope, parent)
    scope
  end

  defp parse_and_bind(text) do
    parse_and_bind(text, Bind.Scope.empty_scope())
  end

  defp parse_and_bind(text, vars) when is_map(vars) do
    scope = Bind.Scope.from_map(vars)
    parse_and_bind2(text, scope)
  end
  defp parse_and_bind2(text, scope, opts \\ []) do
    {:ok, ast} = Parser.scan_and_parse(text, opts)
    {:ok, scope} = Bindable.resolve(ast, scope)
    {:ok, new_ast, _scope} = Bindable.bind(ast, scope)
    {:ok, new_ast}
  end

  defp arg(%Ast.Invocation{}=ast, index) do
    Enum.at(ast.args, index)
  end

  test "preparing simple command" do
    {:ok, ast} = parse_and_bind("echo 'foo'")
    assert "#{ast.name}" == "echo"
    assert arg(ast, 0) == "foo"
    assert "#{ast}" == "echo foo"
  end

  test "preparing command with options" do
    {:ok, ast} = parse_and_bind("ec2:list_vms --region=us-east-1")
    assert "#{ast.name}" == "ec2:list_vms"
    assert "#{arg(ast, 0).name}" == "region"
    assert "#{arg(ast, 0).value}" == "us-east-1"
    assert "#{ast}" == "ec2:list_vms --region=us-east-1"
  end

  test "preparing command with variable arg" do
    {:ok, ast} = parse_and_bind("ec2:list_vms --region=$region", %{"region" => "us-west-1"})
    assert "#{ast.name}" == "ec2:list_vms"
    assert "#{arg(ast, 0).name}" == "region"
    assert "#{arg(ast, 0).value}" == "us-west-1"
    assert "#{ast}" == "ec2:list_vms --region=us-west-1"
  end

  test "preparing command with the same variable multiple times" do
    {:ok, ast} = parse_and_bind("echo $padding $value $padding", %{"padding" => "***", "value" => "cheeseburger"})
    assert "#{ast}" == "echo *** cheeseburger ***"
  end

  test "preparing command with chained scopes" do
    scope_chain = link_scopes([%{"user" => "becky"}, %{"region" => "us-west-2"}, %{"page_count" => 5}])
    {:ok, ast} = parse_and_bind2("ec2:list_vms --region=$region --user=$user $page_count", scope_chain)
    assert "#{ast}" == "ec2:list_vms --region=us-west-2 --user=becky 5"
  end

  # TODO: Add back support for indexed variables
  # test "array indexing" do
  #   scope = Bind.Scope.from_map(%{"region" => ["us-west-1", "us-east-1"]})
  #   {:ok, ast} = parse_and_bind2("ec2:list_vms --region=$region[1]", scope)
  #   assert "#{ast}" == "ec2:list_vms --region=us-east-1"
  # end

  # TODO: Add back support for indexed variables
  # test "map indexing" do
  #   scope = Bind.Scope.from_map(%{"region" => %{"west-1" => "us-west-1", "east" => "us-east-1"}})
  #   {:ok, ast} = parse_and_bind2("ec2:list_vms --region=$region[\"west-1\"]", scope)
  #   assert "#{ast}" == "ec2:list_vms --region=us-west-1"
  # end

end
