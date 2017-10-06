defimpl Piper.Common.Bindable, for: Piper.Command.Ast.Invocation do

  alias Piper.Common.Bindable

  def resolve(invocation, scope) do
    case Enum.reduce_while(invocation.args, {:ok, scope}, &resolve_arg/2) do
      {:ok, scope} ->
        case invocation.redir do
          nil ->
            {:ok, scope}
          redir ->
            Bindable.resolve(redir, scope)
        end
      error ->
        error
    end
  end

  def bind(invocation, scope) do
    case Enum.reduce_while(invocation.args, {:ok, {[], scope}}, &bind_arg/2) do
      {:ok, {updated_args, scope}} ->
        invocation = %{invocation | args: Enum.reverse(updated_args)}
        {:ok, invocation, scope}
        case invocation.redir do
          nil ->
            {:ok, invocation, scope}
          redir ->
            case Bindable.bind(redir, scope) do
              {:ok, updated, scope} ->
                {:ok, %{invocation | redir: updated}, scope}
              error ->
                error
            end
        end
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
