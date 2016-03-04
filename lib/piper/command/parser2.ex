defmodule Piper.Command.Parser2 do

  alias Piper.Command.SemanticError

  def scan_and_parse(text, opts \\ []) do
    try do
      :piper_cmd_parser.scan_and_parse(text, opts)
    catch
      error -> {:error, build_error_message(error)}
    end
  end

  defp build_error_message(%SemanticError{reason: :ambiguous_command, text: name, meta: bundles}) do
    "Ambiguous command reference detected. Command '#{name}' found in bundles #{format_bundles(bundles)}."
  end
  defp build_error_message(%SemanticError{reason: :no_command, text: name}) do
    "Command '#{name}' not found in any installed bundle."
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
