defimpl Piper.Executable, for: Piper.Ast.Invocation do

  alias Piper.Ast.Invocation

  def resolve(%Invocation{command: command, args: args}, scope) do
    case resolve_command(command, scope) do
      {:ok, scope} ->
        resolve_args(args, scope)
      error ->
        error
    end
  end

  def execute(%Invocation{command: command, args: args}=invoke, scope) do
    case execute_command(command, scope) do
      {:ok, command} ->
        case execute_args(args, scope, []) do
          {:ok, args} ->
            {:ok, %{invoke | command: command, args: args}}
          error ->
            error
        end
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

  defp execute_args([], _scope, accum) do
    {:ok, Enum.reverse(accum)}
  end
  defp execute_args([h|t], scope, accum) do
    case Piper.Executable.execute(h, scope) do
      {:ok, arg} ->
        execute_args(t, scope, [arg|accum])
      error ->
        error
    end
  end

  defp execute_command(command, _scope) when is_binary(command) do
    {:ok, command}
  end
  defp execute_command(command, scope) do
    Piper.Executable.execute(command, scope)
  end

  defp resolve_command(command, scope) when is_binary(command) do
    {:ok, scope}
  end
  defp resolve_command(command, scope) do
    Piper.Executable.resolve(command, scope)
  end

end
