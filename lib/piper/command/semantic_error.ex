defmodule Piper.Command.SemanticError do

  defstruct [:text, :reason,
             :meta]


  def new(near, :not_found) do
    error = init(near)
    %{error | reason: :not_found}
  end
  def new(near, {:ambiguous, bundles}) do
    error = init(near)
    %{error | reason: :ambiguous, meta: bundles}
  end
  def new(near, {:bad_bundle, bundle}) do
    error = init(near)
    %{error | reason: :bad_bundle, meta: bundle}
  end
  def new(near, {:bad_command, command}) do
    error = init(near)
    %{error | reason: :bad_command, meta: command}
  end
  def new(near, {:expansion_limit, alias, limit}) do
    error = init(near)
    %{error | reason: :expansion_limit, meta: {alias, limit}}
  end
  def new(near, {:alias_cycle, cycle}) do
    error = init(near)
    %{error | reason: :alias_cycle, meta: cycle}
  end

  def format_error(%__MODULE__{text: text, reason: reason, meta: meta}) do
    {:error, message_for_reason(reason, text, meta)}
  end

  defp message_for_reason(:not_found, text, _) do
    "Command '#{text}' not found in any installed bundle."
  end
  defp message_for_reason(:ambiguous, text, bundles) do
    "Ambiguous command reference detected. " <>
    "Command '#{text}' found in bundles #{format_bundles(bundles)}."
  end
  defp message_for_reason(:bad_bundle, text, bundle) do
    "Failed to parse bundle name '#{bundle}' for command '#{text}'. Bundle names must be a string or emoji."
  end
  defp message_for_reason(:bad_command, text, command) do
    "Replacing command name '#{text}' with '#{command}' failed. Command names must be a string or emoji."
  end
  defp message_for_reason(:expansion_limit, _last_alias, {first_alias, limit}) do
    "Alias expansion limit (#{limit}) exceeded starting with alias '#{first_alias}'."
  end
  defp message_for_reason(:alias_cycle, _text, [first, last]) do
    "Infinite alias expansion loop detected '#{first}' -> '#{last}'."
  end

  defp init({_, _, text}) do
    %__MODULE__{text: String.Chars.to_string(text)}
  end
  defp init(%{value: value}) do
    %__MODULE__{text: value}
  end
  defp init(text) when is_binary(text) do
    %__MODULE__{text: text}
  end

  defp format_bundles(bundles) do
    format_bundles(bundles, "")
  end
  defp format_bundles([bundle|rest], accum) when rest == [] do
    accum <> ", and '#{bundle}'"
  end
  defp format_bundles([bundle|rest], "") do
    format_bundles(rest, "'#{bundle}'")
  end
  defp format_bundles([bundle|rest], accum) do
    format_bundles(rest, accum <> ", '#{bundle}'")
  end

end
