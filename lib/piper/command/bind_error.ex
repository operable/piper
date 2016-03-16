defmodule Piper.Command.BindError do

  defstruct [:text, :reason,
             :meta]

  def new(near, {:out_of_bounds, index}) do
    error = init(near)
    %{error | reason: :out_of_bounds, meta: index}
  end
  def new(near, {:missing_key, key}) do
    error = init(near)
    %{error | reason: :missing_key, meta: key}
  end

  def format_error(%__MODULE__{text: text, reason: reason, meta: meta}) do
    {:error, message_for_reason(reason, text, meta)}
  end

  defp message_for_reason(:out_of_bounds, text, index) do
    "Index #{index} out of bounds in expression '#{text}'."
  end
  defp message_for_reason(:missing_key, text, key) do
    "Key '#{key}' not found in expression '#{text}'."
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

end
