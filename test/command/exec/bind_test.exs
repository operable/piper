defmodule Bind.BindTest do

  use ExUnit.Case

  alias Piper.Common.Scope
  alias Piper.Command.Ast, as: Ast

  use Piper.Test.BindHelpers

  defp arg(%Ast.Pipeline{}=ast, index) do
    Enum.at(ast.stages.left.args, index)
  end

  test "preparing simple command" do
    {:ok, ast} = parse_and_bind("echo 'foo'")
    assert "#{ast.stages.left.name}" == "echo"
    assert arg(ast, 0) == "foo"
    assert "#{ast}" == "echo foo"
  end

  test "preparing command with options" do
    {:ok, ast} = parse_and_bind("ec2:list_vms --region=us-east-1")
    assert "#{ast.stages.left.name}" == "ec2:list_vms"
    assert "#{arg(ast, 0).name}" == "region"
    assert "#{arg(ast, 0).value}" == "us-east-1"
    assert "#{ast}" == "ec2:list_vms --region=us-east-1"
  end

  test "preparing command with variable arg" do
    {:ok, ast} = parse_and_bind("ec2:list_vms --region=$region", %{"region" => "us-west-1"})
    assert "#{ast.stages.left.name}" == "ec2:list_vms"
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

  test "missing option value variable fails" do
    result = parse_and_bind("test:test --opt=$var")
    assert result == {:error, "Key 'var' not found in expression '$var'."}
  end

  test "missing arg value variable fails" do
    result = parse_and_bind("test:test $var")
    assert result == {:error, "Key 'var' not found in expression '$var'."}
  end

  # go up the chain, too

  # TODO: Find a better way to prevent this. Raising BadValueError in
  # to_string is janky.

  # test "binding a map to a variable fails" do
  #   scope = Scope.from_map(%{"foo" => %{"bar" => 123}})
  #   {:ok, ast} = parse_and_bind2("my:cmd --test=$foo", scope)
  #   assert_raise BadValueError, fn() -> "#{ast}" end
  # end

  test "array indexing" do
    scope = Scope.from_map(%{"region" => ["us-west-1", "us-east-1"]})
    {:ok, ast} = parse_and_bind2("ec2:list_vms --region=$region[1]", scope)
    assert "#{ast}" == "ec2:list_vms --region=us-east-1"
  end

  test "map indexing" do
    scope = Scope.from_map(%{"envs" => %{"prod" => "us-east-1", "test" => "us-west-2"}})
    {:ok, ast} = parse_and_bind2("ec2:list_vms --region=$envs.prod", scope)
    assert "#{ast}" == "ec2:list_vms --region=us-east-1"
  end

  test "nested access" do
    envs = [%{"region" => "us-east-1", "owner" => "admin1"}, %{"region" => "us-west-2", "owner" => "admin2"}]
    scope = Scope.from_map(%{"envs" => envs})
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$envs[0].region --notify=$envs[0].owner", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-east-1 --notify=admin1"
  end

  test "moar nested access" do
    envs = [%{"region" => "us-east-1", "owners" => ["admin1", "admin3"]}, %{"region" => "us-west-2", "owners" => ["admin2"]}]
    scope = Scope.from_map(%{"envs" => envs})
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$envs[0].region --notify=$envs[0].owners[1]", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-east-1 --notify=admin3"
  end

  test "even moar nested access" do
    env = %{"author" => %{"user" => %{"handle" => "buffy"}}}
    scope = Scope.from_map(env)
    {:ok, ast} = parse_and_bind2("echo $author[user][handle]", scope)
    assert "#{ast}" == "echo buffy"
    {:ok, ast} = parse_and_bind2("echo $author.user.handle", scope)
    assert "#{ast}" == "echo buffy"
  end

  test "nested access with spaces in keys" do
    envs = [%{"region" => "us-east-1", "env owners" => ["admin1", "admin3"]}, %{"region" => "us-west-2", "owner" => "admin2"}]
    scope = Scope.from_map(%{"envs" => envs})
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$envs[0].region --notify=$envs[0].'env owners'[1]", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-east-1 --notify=admin3"
  end

  test "old school map access" do
    envs = [%{"region" => "us-east-1", "env owners" => ["admin1", "admin3"]}, %{"region" => "us-west-2", "owner" => "admin2"}]
    scope = Scope.from_map(%{"envs" => envs})
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$envs[0][region] --notify=$envs[0]['env owners'][1]", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-east-1 --notify=admin3"
  end

  test "index out of bounds" do
    envs = [%{"region" => "us-east-1", "env owners" => ["admin1", "admin3"]}, %{"region" => "us-west-2", "owner" => "admin2"}]
    scope = Scope.from_map(%{"envs" => envs})
    {:error, message} = parse_and_bind2("site:monkey_with_vms --region=$envs[2][region] --notify=$envs[0]['env owners'][1]", scope)
    assert message == "Index 2 out of bounds in expression '$envs[2].region'."
    {:error, message} = parse_and_bind2("site:monkey_with_vms --region=$envs[0][region] --notify=$envs[0][envowners][1]", scope)
    assert message == "Key 'envowners' not found in expression '$envs[0].envowners[1]'."
  end

  test "bound variable redirects" do
    scope = Scope.from_map(%{"room" => "#ops", "region" => "us-west-2"})
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$region *> $room #foo", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-west-2 *> #ops #foo"
  end

  test "interpolated string redirects" do
    scope = Scope.from_map(%{"rooms" => ["ops", "general"], "region" => "us-west-2"})
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$region > '#${rooms[0]}'", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-west-2 > #ops"
    {:ok, ast} = parse_and_bind2("site:monkey_with_vms --region=$region *> '#${rooms[1]}' '#${rooms[0]}'", scope)
    assert "#{ast}" == "site:monkey_with_vms --region=us-west-2 *> #general #ops"
  end

  test "badly formatted url redirects return an error" do
    scope = Scope.from_map(%{"rooms" => ["ops", "general", "chat:badly"]})
    {:error, reason} = parse_and_bind2("echo foo > $rooms[2]", scope)
    assert reason == "URL redirect targets must begin with 'chat://'. Found 'chat:badly'."
    {:error, reason} = parse_and_bind2("echo foo > 'chat:${rooms[0]}'", scope)
    assert reason == "URL redirect targets must begin with 'chat://'. Found 'chat:ops'."
    {:ok, ast} = parse_and_bind2("echo foo > 'chat://${rooms[1]}'", scope)
    assert "#{ast}" == "echo foo > chat://general"
  end

  test "bound redirects are accesible from ast node" do
    scope = Scope.from_map(%{"rooms" => ["#ops", "ops"]})
    {:ok, ast} = parse_and_bind2("echo foo > $rooms[0]", scope)
    redirect = Ast.Pipeline.redirect(ast)
    assert redirect != nil
    assert Ast.Pipeline.raw_redirect_targets(ast) == ["#ops"]
    {:ok, ast} = parse_and_bind2("echo foo > \"#${rooms[1]}\" $rooms[0]", scope)
    assert Ast.Pipeline.raw_redirect_targets(ast) == ["#ops", "#ops"]
  end

end
