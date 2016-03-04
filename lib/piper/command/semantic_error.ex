defmodule Piper.Command.SemanticError do

  defstruct [:col, :line, :text, :reason,
             :meta]


  def new(near, :no_command) do
    error = new_with_position(near)
    %{error | reason: :no_command}
  end
  def new(near, {:ambiguous_command, bundles}) do
    error = new_with_position(near)
    %{error | reason: :ambiguous_command, meta: bundles}
  end

  def format_error(%__MODULE__{col: col, line: line, text: text, reason: reason, meta: meta}) do
    {:error, position_info(col, line) <> message_for_reason(reason, text, meta)}
  end

  defp position_info(nil, _), do: ""
  defp position_info(col, line) do
    "(Line: #{line}, Col: #{col}) "
  end

  defp message_for_reason(:no_command, text, _) do
    "Command '#{text}' not found in any installed bundle."
  end
  defp message_for_reason(:ambiguous_command, text, bundles) do
    "Ambiguous command reference detected. " <>
    "Command '#{text}' found in bundles #{format_bundles(bundles)}."
  end

  defp new_with_position(%Token{col: col, line: line, text: text}) do
    %__MODULE__{col: col, line: line, text: text}
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
