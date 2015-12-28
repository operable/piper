defmodule Piper.Command.SemanticError do

  defstruct [:col, :line, :text, :reason,
             :meta]

  alias Piper.Util.Token

  def new(near, :no_command) do
    error = new_with_position(near)
    %{error | reason: :no_command}
  end
  def new(near, {:ambiguous_command, bundles}) do
    error = new_with_position(near)
    %{error | reason: :ambiguous_command, meta: bundles}
  end

  def update_position(error, %Token{line: line, col: col, text: text}) do
    %{error | line: line, col: col, text: text}
  end

  def format_error(%__MODULE__{col: col, line: line, text: text, reason: reason, meta: meta}) do
    {:error, position_info(col, line, text) <> message_for_reason(reason, text, meta)}
  end

  defp position_info(nil, _, _), do: ""
  defp position_info(col, line, text) do
    "Error on line #{line}, column #{col}, starting at '#{text}'. "
  end

  defp message_for_reason(:no_command, text, _) do
    "Installed command with name '#{text}' not found."
  end
  defp message_for_reason(:ambiguous_command, text, bundles) do
    bundles = Enum.join(bundles, ", ")
    "Command name '#{text}' found in multiple bundles: #{bundles}."
  end

  defp new_with_position(%Token{col: col, line: line, text: text}) do
    %__MODULE__{col: col, line: line, text: text}
  end
  defp new_with_position(near) when is_binary(near) do
    %__MODULE__{text: near}
  end

end
