defmodule Bind.BindTest do

  use ExUnit.Case

  alias Piper.Parser
  alias Piper.Bindable
  alias Piper.Bind

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
    {:ok, scope} = Piper.Scoped.set_parent(scope, parent)
    scope
  end

  defp parse_and_bind(text) do
    parse_and_bind(text, Bind.Scope.empty_scope())
  end

  defp parse_and_bind(text, vars) when is_map(vars) do
    scope = Bind.Scope.from_map(vars)
    parse_and_bind2(text, scope)
  end
  defp parse_and_bind2(text, scope) do
    {:ok, ast} = Parser.scan_and_parse(text)
    {:ok, scope} = Bindable.resolve(ast, scope)
    {:ok, new_ast, _scope} = Bindable.bind(ast, scope)
    {:ok, ast, new_ast}
  end

  test "preparing simple command" do
    {:ok, ast, new_ast} = parse_and_bind("echo 'foo'")
    assert ast == new_ast
  end

  test "preparing command with options" do
    {:ok, ast, new_ast} = parse_and_bind("ec2:list_vms --region=us-east-1")
    assert ast == new_ast
  end

  test "preparing command with variable arg" do
    {:ok, ast, new_ast} = parse_and_bind("ec2:list_vms --region=$region", %{"region" => "us-west-1"})
    assert ast != new_ast
    assert "#{new_ast}" == "ec2:list_vms --region=us-west-1"
  end

  test "preparing command with variable option and option value" do
    {:ok, ast, new_ast} = parse_and_bind("ec2:list_vms --$region_opt=$region", %{"region_opt" => "region",
                                                                                    "region" => "us-west-2"})
    assert ast != new_ast
    assert "#{new_ast}" == "ec2:list_vms --region=us-west-2"
  end

  test "preparing command with variable option" do
    {:ok, ast, new_ast} = parse_and_bind("ec2:list_vms --$region_opt=us-east-1", %{"region_opt" => "region"})
    assert ast != new_ast
    assert "#{new_ast}" == "ec2:list_vms --region=us-east-1"
  end

  test "preparing command with chained scopes" do
    scope_chain = link_scopes([%{"user" => "becky"}, %{"region" => "us-west-2"}, %{"page_count" => 5}])
    {:ok, ast, new_ast} = parse_and_bind2("ec2:list_vms --region=$region --user=$user $page_count", scope_chain)
    assert ast != new_ast
    assert "#{new_ast}" == "ec2:list_vms --region=us-west-2 --user=becky 5"
  end

end
