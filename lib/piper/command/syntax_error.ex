defmodule Piper.Command.SyntaxError do

  defstruct [:parsing, :wanted, :col, :line, :type, :text]

  alias Piper.Util.Token

  def new(parsing, wanted, %Token{}=found) do
    %__MODULE__{parsing: parsing,
                wanted: ensure_list(wanted),
                line: found.line,
                col: found.col,
                type: found.type,
                text: found.text}
  end
  def new(parsing, wanted, nil) do
    %__MODULE__{parsing: parsing,
                wanted: ensure_list(wanted),
                col: -1,
                line: -1,
                type: :eol,
                text: ""}
  end

  def update_error(%__MODULE__{}=wrong_type, new_opts) do
    Enum.reduce(Keyword.keys(new_opts), wrong_type,
      fn(key, wrong_type) ->
        v1 = Map.get(wrong_type, key)
        v2 = Keyword.fetch!(new_opts, key)
        Map.put(wrong_type, key, update_wrong_type(key, v1, v2))
      end)
  end

  def format_error(%__MODULE__{parsing: parsing,
                               wanted: wanted,
                               line: line,
                               col: col,
                               type: type,
                               text: text}) do
    msg = "Attempted to parse #{parsing}. " <>
          "Expected #{format_alternatives(wanted)} but found #{format_type(type)}" <>
          format_position(line, col, text)
    {:error, msg}
  end

  defp format_type(:eol) do
    "end of input"
  end
  defp format_type(type) do
    type
  end

  defp format_position(-1, _, _) do
    "."
  end
  defp format_position(line, col, text) do
    " on line #{line}, column #{col} starting at '#{text}'."
  end
  defp format_alternatives(alts) when length(alts) < 3 do
    Enum.join(alts, " or ")
  end
  defp format_alternatives(alts) do
    [h|t] = Enum.reverse(alts)
    alts = Enum.reverse(t)
    Enum.join(alts, ", ") <> " or #{h}"
  end

  defp update_wrong_type(:parsing, _v1, v2),
    do: v2
  defp update_wrong_type(:wanted, v1, v2) when is_list(v2) do
    Enum.uniq(v1 ++ v2)
  end
  defp update_wrong_type(:wanted, v1, v2) do
    Enum.uniq([v2|v1])
  end

  defp ensure_list(value) when is_list(value) do
    value
  end
  defp ensure_list(value) do
    [value]
  end
end
