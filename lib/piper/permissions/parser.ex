defmodule Piper.Permissions.Parser.Tracker do

  def new() do
    Agent.start_link(fn -> %{perms: HashSet.new(),
                             args: HashSet.new(),
                             options: HashSet.new()} end)
  end

  def add_permission(tracker, permission) do
    Agent.update(tracker, fn(state) ->
      if Set.member?(state.perms, permission) do
        state
      else
        %{state | perms: Set.put(state.perms, permission)}
      end
    end)
  end

  def add_option(tracker, name) do
    Agent.update(tracker, fn(state) ->
      if Set.member?(state.perms, name) do
        state
      else
        %{state | options: Set.put(state.options, name)}
      end
    end)
  end

  def add_arg(tracker, index) do
    Agent.update(tracker, fn(state) ->
      if Set.member?(state.args, index) do
        state
      else
        %{state | args: Set.put(state.args, index)}
      end
    end)
  end

  def list_permissions(tracker) do
    Agent.get(tracker, fn(state) -> Enum.sort(Set.to_list(state.perms)) end)
  end

  def get_score(tracker) do
    options = Agent.get(tracker, fn(state) -> state.options end)
    args = Agent.get(tracker, fn(state) -> state.args end)
    compute_score(options) + compute_score(args)
  end

  def stop(tracker) do
    Agent.stop(tracker)
  end

  defp compute_score(values) do
    score = Set.size(values)
    cond do
      :any in values ->
        (score  - 1) + 3
      :all in values ->
        (score - 1) + 3
      true ->
        score
    end
  end

end

defmodule Piper.Permissions.Parser do

  alias Piper.Permissions.Parser.Tracker
  alias Piper.Permissions.Ast

  def parse(text, opts \\ [json: false])

  def parse(%Ast.Rule{}=rule, _opts) do
    raise "Attempting to parse a JSON-ified rule for command #{rule.command}!"
  end
  def parse(text, opts) when is_binary(text) do
    {:ok, tracker} = Tracker.new
    updater = fn(kind, thing) -> update_tracker(tracker, kind, thing) end
    try do
      case :piper_rule_parser.parse_rule(text, updater) do
        {:ok, ast} ->
          score = Tracker.get_score(tracker)
          {:ok, format_ast(%{ast | score: score}, opts),
           Tracker.list_permissions(tracker)}
        error ->
          error
      end
    after
      Tracker.stop(tracker)
    end
  end

  def rule_to_json!(%Ast.Rule{}=rule) do
    Poison.encode!(rule)
  end

  def json_to_rule!(json) when is_binary(json) do
    json = Poison.decode!(json)
    Piper.Permissions.Json.from_json!(json, json)
  end

  defp update_tracker(tracker, :permission, thing) do
    Tracker.add_permission(tracker, thing)
  end
  defp update_tracker(tracker, :option, thing) do
    Tracker.add_option(tracker, thing)
  end
  defp update_tracker(tracker, :arg, thing) do
    Tracker.add_arg(tracker, thing)
  end

  defp format_ast(ast, [json: true]) do
    rule_to_json!(ast)
  end
  defp format_ast(ast, _) do
    ast
  end

end
