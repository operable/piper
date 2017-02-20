defimpl Piper.Common.Bindable, for: Piper.Command.Ast.Redirect do

  alias Piper.Command.Ast.Variable
  alias Piper.Command.Ast.InterpolatedString
  alias Piper.Common.Bindable

  def resolve(redirect, scope) do
    Enum.reduce_while(redirect.targets, {:ok, scope}, &resolve_target/2)
  end

  def bind(redirect, scope) do
    case Enum.reduce_while(redirect.targets, {:ok, {[], scope}}, &bind_target/2) do
      {:ok, {updated_targets, scope}} ->
        with :ok <- Enum.reduce_while(updated_targets, :ok, &validate_target/2) do
          {:ok, %{redirect | targets: Enum.reverse(updated_targets)}, scope}
        end
      error ->
        error
    end
  end

  defp resolve_target(target, {:ok, scope}) do
    case Bindable.resolve(target, scope) do
      {:ok, scope} ->
        {:cont, {:ok, scope}}
      error ->
        {:halt, error}
    end
  end

  defp bind_target(target, {:ok, {accum, scope}}) do
    case Bindable.bind(target, scope) do
      {:ok, updated, scope} ->
        {:cont, {:ok, {[updated|accum], scope}}}
      error ->
        {:halt, error}
    end
  end

  defp validate_target(%Variable{value: value}, acc) do
    validate_target(value, acc)
  end
  defp validate_target(%InterpolatedString{}=target, acc) do
    validate_target("#{target}", acc)
  end
  defp validate_target(value, _) when is_binary(value) do
    if String.starts_with?(value, "chat:") do
      if String.starts_with?(value, "chat://") do
        {:cont, :ok}
      else
        {:halt, {:error, "URL redirect targets must begin with 'chat://'. Found '#{value}'."}}
      end
    else
      {:cont, :ok}
    end
  end

end
