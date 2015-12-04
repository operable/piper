defimpl String.Chars, for: Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  def to_string(%Ast.Pipeline{invocations: invocations, type: type}) do
    to_string(invocations, separator(type), "")
  end

  defp to_string([], _sep, accum) do
    accum
  end
  defp to_string([%Ast.Pipeline{type: type, invocations: invocations}|t], sep, accum) do
    accum = to_string(invocations, separator(type), accum)
    to_string(t, sep, accum)
  end
  defp to_string([h|t], sep, "") do
    to_string(t, sep, "#{h}")
  end
  defp to_string([h|t], sep, accum) do
    to_string(t, sep, accum <> "#{sep}#{h}")
  end

  defp separator(:pipe) do
    " | "
  end
  defp separator(:iff) do
    " && "
  end

end
