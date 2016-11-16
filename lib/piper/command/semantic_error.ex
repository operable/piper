defmodule Piper.Command.SemanticError do

  defstruct [:text, :reason,
             :meta]


  def new(near, {reason, meta}) do
    error = init(near)
    %{error | reason: reason, meta: meta}
  end
  def new(near, reason) do
    error = init(near)
    %{error | reason: reason}
  end

  def new({:syntax, message}) do
    error = init(message)
    %{error | reason: :syntax}
  end

  def format_error(%__MODULE__{text: text, reason: reason, meta: meta}) do
    {:error, message_for_reason(reason, text, meta)}
  end

  defp message_for_reason(:not_found, text, _) do
    "Command '#{text}' not found in any installed bundle."
  end
  defp message_for_reason(:bundle_not_found, _, bundle) do
    "Bundle '#{bundle}' was not found. Please check the name and try again."
  end
  defp message_for_reason(:not_in_bundle, text, bundle) do
    "Bundle '#{bundle}' doesn't contain a command named '#{text}'."
  end
  defp message_for_reason(:not_enabled, _, bundle) do
    "Bundle '#{bundle}' is disabled. Please enable it and try running the command again."
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
  defp message_for_reason(:syntax, text, _) do
    text
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
