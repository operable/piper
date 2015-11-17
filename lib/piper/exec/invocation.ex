defimpl Piper.Executable, for: Piper.Ast.Invocation do

  alias Piper.Ast.Invocation

  def prepare(%Invocation{command: command, args: args}=invoke, scope) do
    case prepare_command(command, scope) do
      {:ok, command, scope} ->
        case prepare_args(args, scope, []) do
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
    case Piper.Executable.resolve(h, scope) do
      {:ok, scope} ->
        resolve_args(t, scope)
      error ->
        error
    end
  end

  defp prepare_args([], scope, accum) do
    {:ok, Enum.reverse(accum), scope}
  end
  defp prepare_args([h|t], scope, accum) do
    case Piper.Executable.prepare(h, scope) do
      {:ok, arg, scope} ->
        prepare_args(t, scope, [arg|accum])
      error ->
        error
    end
  end

  defp prepare_command(command, scope) when is_binary(command) do
    {:ok, command, scope}
  end
  defp prepare_command(command, scope) do
    Piper.Executable.prepare(command, scope)
  end

  defp resolve_command(command, scope) when is_binary(command) do
    {:ok, scope}
  end
  defp resolve_command(command, scope) do
    Piper.Executable.resolve(command, scope)
  end

end
