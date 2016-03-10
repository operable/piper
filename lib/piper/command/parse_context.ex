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

  def start_alias(tracker, alias) do
    GenServer.call(tracker, {:start, alias}, :infinity)
  end

  def finish_alias(tracker, alias) do
    GenServer.call(tracker, {:finish, alias}, :infinity)
  end

  defp do_start_line(state, linenum) do
    %{state | linenum: linenum, current_token: 1, next_token: 0}
  end

  defp do_advance_count(state, count) do
    %{state | current_token: state.next_token, next_token: state.next_token + count}
  end

  def handle_call({:start, alias}, _from, state) do
    case List.keyfind(state.expansions, alias, 0) do
      nil ->
        {:reply, :ok, %{state | expansions: [{alias, 1}|state.expansions]}}
      {^alias, count} ->
        updated = {alias, count + 1}
        updated_state = %{state | expansions: List.keyreplace(state.expansions, alias, 0, updated)}
        if over_depth_limit?(updated_state) do
          {:reply, {:error, {:max_depth, state.max_depth}}, state}
        else
          {:reply, :ok, updated_state}
        end
    end
  end

  def handle_call({:finish, alias}, _from, state) do
    case List.keyfind(state.expansions, alias, 0) do
      nil ->
        {:reply, :ok, state}
      {^alias, 1} ->
        {:reply, :ok, %{state | expansions: List.keydelete(state.expansions, alias, 0)}}
      {^alias, count} ->
        updated = {alias, count - 1}
        {:reply, :ok, %{state | expansions: List.keyreplace(state.expansions, alias, 0, updated)}}
    end
  end

  def handle_call(:dispose, _from, _state) do
    {:stop, :shutdown, :ok, nil}
  end

  defp over_depth_limit?(state) do
    current_depth = Enum.reduce(state.expansions, 0, fn({_, count}, acc) -> acc + count end)
    IO.puts "#{current_depth} #{state.max_depth}"
    current_depth > state.max_depth
  end

end
