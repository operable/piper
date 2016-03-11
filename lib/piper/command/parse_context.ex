defmodule Piper.Command.ParseContext do

  @moduledoc """
  Contextual lex and parse information used during lexing,
  parsing, and alias expansion.
  """

  alias Piper.Command.ParserOptions

  defstruct expansions: [], max_depth: nil, linenum: 1,
            current_token: 1, next_token: 1, parse_options: nil


  def start_link(max_depth) when is_integer(max_depth) do
    Agent.start_link(fn() -> %__MODULE__{max_depth: max_depth} end)
  end
  def start_link(%ParserOptions{}=options) do
    Agent.start_link(fn() -> %__MODULE__{max_depth: options.expansion_limit,
                                         parse_options: options} end)
  end

  def stop(agent) do
    Agent.stop(agent)
  end

  def start_line(agent, linenum) do
    Agent.update(agent, &(do_start_line(&1, linenum)))
  end

  def advance_count(agent, count) do
    Agent.update(agent, &(do_advance_count(&1, count)))
  end

  def position(agent) do
    Agent.get(agent, fn(state) -> {state.linenum, state.current_token} end)
  end

  def get_options(agent) do
    Agent.get(agent, fn(state) -> state.parse_options end)
  end

  def start_alias(agent, alias) do
    Agent.get_and_update(agent, &(do_start_alias(&1, alias)))
  end

  def finish_alias(agent, alias) do
    Agent.update(agent, &(do_finish_alias(&1, alias)))
  end

  defp do_start_line(state, linenum) do
    %{state | linenum: linenum, current_token: 1, next_token: 0}
  end

  defp do_advance_count(state, count) do
    %{state | current_token: state.next_token, next_token: state.next_token + count}
  end

  defp do_start_alias(state, alias) do
    case List.keyfind(state.expansions, alias, 0) do
      nil ->
        updated_state = %{state | expansions: [{alias, 1}|state.expansions]}
        if over_depth_limit?(updated_state) do
          max_depth_error(updated_state)
        else
          {:ok, updated_state}
        end
      {^alias, count} ->
        updated = {alias, count + 1}
        updated_state = %{state | expansions: List.keyreplace(state.expansions, alias, 0, updated)}
        if over_depth_limit?(updated_state) do
          analyze_error(state)
        else
          {:ok, updated_state}
        end
    end
  end

  def do_finish_alias(state, alias) do
    case List.keyfind(state.expansions, alias, 0) do
      nil ->
        state
      {^alias, 1} ->
        %{state | expansions: List.keydelete(state.expansions, alias, 0)}
      {^alias, count} ->
        updated = {alias, count - 1}
        %{state | expansions: List.keyreplace(state.expansions, alias, 0, updated)}
    end
  end

  defp analyze_error(state) do
    expansions = Enum.reverse(state.expansions)
    {{min_alias, min}, {max_alias, max}} = Enum.min_max_by(expansions, fn({_, count}) -> count end)
    cond do
      min == max ->
        max_depth_error(state)
      max - min in 0..1 ->
        alias_cycle_error([min_alias, max_alias], state)
      true ->
        expansions
        |> Enum.filter(fn({_, count}) -> max - count in -1..1 end)
        |> Enum.map(fn({alias, _}) -> alias end)
        |> Enum.unique
        |> alias_cycle_error(state)
    end
  end

  defp over_depth_limit?(state) do
    current_depth = Enum.reduce(state.expansions, 0, fn({_, count}, acc) -> acc + count end)
    current_depth > state.max_depth
  end

  defp max_depth_error(state) do
    [{root_alias, _}|_] = Enum.reverse(state.expansions)
    {{:error, {:max_depth, root_alias, state.max_depth}}, state}
  end

  defp alias_cycle_error(cycle, state) do
    {{:error, {:alias_cycle, cycle}}, state}
  end

end
