defmodule Piper.Command.SemanticError do

  defstruct [:col, :line, :text, :reason,
             :meta]


  def new(near, :not_found) do
    error = new_with_position(near)
    %{error | reason: :not_found}
  end
  def new(near, {:ambiguous, bundles}) do
    error = new_with_position(near)
    %{error | reason: :ambiguous, meta: bundles}
  end
  def new(near, {:bad_bundle, bundle}) do
    error = new_with_position(near)
    %{error | reason: :bad_bundle, meta: bundle}
  end
  def new(near, {:bad_command, command}) do
    error = new_with_position(near)
    %{error | reason: :bad_command, meta: command}
  end
  def format_error(%__MODULE__{col: col, line: line, text: text, reason: reason, meta: meta}) do
    {:error, position_info(col, line) <> message_for_reason(reason, text, meta)}
  end

  defp position_info(nil, _), do: ""
  defp position_info(col, line) do
    "(Line: #{line}, Col: #{col}) "
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

  defp new_with_position({_, {line, col}, text}) do
    %__MODULE__{line: line, col: col, text: String.Chars.to_string(text)}
  end
  defp new_with_position(%{line: line, col: col, value: value}) do
    %__MODULE__{line: line, col: col, text: value}
  end
  defp new_with_position(near) when is_binary(near) do
    %__MODULE__{text: near}
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
