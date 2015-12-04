defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Invocation do

  alias Piper.Command.Ast.Invocation

  def bind(%Invocation{command: command, args: args}=invoke, scope) do
    case bind_command(command, scope) do
      {:ok, command, scope} ->
        case bind_args(args, scope, []) do
          {:ok, args, scope} ->
            {:ok, %{invoke | command: command, args: args}, scope}
          error ->
            error
        end
      error ->
        error
    end
  end

  def resolve(%Invocation{command: command, args: args}, scope) do
    case resolve_command(command, scope) do
      {:ok, scope} ->
        resolve_args(args, scope)
      error ->
        error
    end
  end

  defp resolve_args([], scope) do
    {:ok, scope}
  end
  defp resolve_args([h|t], scope) do
    case Piper.Command.Bindable.resolve(h, scope) do
      {:ok, scope} ->
        resolve_args(t, scope)
      error ->
        error
    end
  end

  defp bind_args([], scope, accum) do
    {:ok, Enum.reverse(accum), scope}
  end
  defp bind_args([h|t], scope, accum) do
    case Piper.Command.Bindable.bind(h, scope) do
      {:ok, arg, scope} ->
        bind_args(t, scope, [arg|accum])
      error ->
        error
    end
  end

  defp bind_command(command, scope) when is_binary(command) do
    {:ok, command, scope}
  end
  defp bind_command(command, scope) do
    Piper.Command.Bindable.bind(command, scope)
  end

  defp resolve_command(command, scope) when is_binary(command) do
    {:ok, scope}
  end
  defp resolve_command(command, scope) do
    Piper.Command.Bindable.resolve(command, scope)
  end

end
