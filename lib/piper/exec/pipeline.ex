defimpl Piper.Executable, for: Piper.Ast.Pipeline do

  alias Piper.Ast

  def resolve(%Ast.Pipeline{invocations: invocations}, scope) do
    resolve_invocations(invocations, scope)
  end

  def prepare(%Ast.Pipeline{invocations: invocations}=pipeline, scope) do
    case prepare_invocations(invocations, [], scope) do
      {:ok, invocations, scope} ->
        {:ok, %{pipeline | invocations: invocations}, scope}
      error ->
        error
    end
  end

  defp resolve_invocations([], scope) do
    {:ok, scope}
  end
  defp resolve_invocations([h|t], scope) do
    case Piper.Executable.resolve(h, scope) do
      {:ok, scope} ->
        resolve_invocations(t, scope)
      error ->
        error
    end
  end

  defp prepare_invocations([], accum, scope) do
    {:ok, Enum.reverse(accum), scope}
  end
  defp prepare_invocations([h|t], accum, scope) do
    case Piper.Executable.prepare(h, scope) do
      {:ok, new_h, scope} ->
        prepare_invocations(t, [new_h|accum], scope)
      error ->
        error
    end
  end

end
