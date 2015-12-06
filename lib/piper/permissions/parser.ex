defmodule Piper.Permissions.Parser.Tracker do

  def new() do
    Agent.start_link(fn -> HashSet.new() end)
  end

  def add_permission(tracker, permission) do
    Agent.update(tracker, fn(state) ->
      if Set.member?(state, permission) do
        state
      else
        Set.put(state, permission)
      end
    end)
  end

  def list_permissions(tracker) do
    Agent.get(tracker, fn(state) -> Enum.sort(Set.to_list(state)) end)
  end

  def stop(tracker) do
    Agent.stop(tracker)
  end

end

defmodule Piper.Permissions.Parser do

  alias Piper.Permissions.Parser.Tracker

  def parse(text) when is_binary(text) do
    {:ok, tracker} = Tracker.new
    updater = fn(permission) -> Tracker.add_permission(tracker, permission) end
    try do
      case :piper_rule_parser.parse_rule(text, updater) do
        {:ok, ast} ->
          {:ok, ast, Tracker.list_permissions(tracker)}
        error ->
          error
      end
    after
      Tracker.stop(tracker)
    end
  end

end
