defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Invocation do

  alias Piper.Command.Bindable

  def resolve(invocation, scope) do
    Enum.reduce_while(invocation.args, {:ok, scope}, &resolve_arg/2)
  end

  def bind(invocation, scope) do
    case Enum.reduce_while(invocation.args, {:ok, {[], scope}}, &bind_arg/2) do
      {:ok, {updated_args, scope}} ->
        {:ok, %{invocation | args: Enum.reverse(updated_args)}, scope}
      error ->
        error
    end
  end

  defp resolve_arg(arg, {:ok, scope}) do
    case Bindable.resolve(arg, scope) do
      {:ok, scope} ->
        {:cont, {:ok, scope}}
      error ->
        {:halt, error}
    end
  end

  defp bind_arg(arg, {:ok, {accum, scope}}) do
    case Bindable.bind(arg, scope) do
      {:ok, updated, scope} ->
        {:cont, {:ok, {[updated|accum], scope}}}
      error ->
        {:halt, error}
    end
  end

end
