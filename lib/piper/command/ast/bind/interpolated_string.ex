defimpl Piper.Common.Bindable, for: Piper.Command.Ast.InterpolatedString do

  alias Piper.Common.Bindable
  alias Piper.Command.Ast.InterpolatedString

  def resolve(%InterpolatedString{}=interp, scope) do
    Enum.reduce_while(interp.exprs, {:ok, scope}, &resolve_exprs/2)
  end

  def bind(%InterpolatedString{}=interp, scope) do
    case Enum.reduce_while(interp.exprs, {:ok, scope, []}, &bind_exprs/2) do
      {:ok, scope, exprs} ->
        {:ok, %{interp | exprs: Enum.reverse(exprs), bound: true}, scope}
      error ->
        error
    end
  end

  defp resolve_exprs(expr, {:ok, scope}) do
    case Bindable.resolve(expr, scope) do
      {:ok, scope} ->
        {:cont, {:ok, scope}}
      error ->
        {:halt, error}
    end
  end

  defp bind_exprs(expr, {:ok, scope, accum}) do
    case Bindable.bind(expr, scope) do
      {:ok, expr, scope} ->
        {:cont, {:ok, scope, [expr|accum]}}
      error ->
        {:halt, error}
    end
  end

end
