defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Option do

  alias Piper.Command.Bindable

  def resolve(option, scope) do
    if option.value != nil do
      Bindable.resolve(option.value, scope)
    else
      {:ok, scope}
    end
  end

  def bind(option, scope) do
    if option.value != nil do
      case Bindable.bind(option.value, scope) do
        {:ok, updated, scope} ->
          {:ok, %{option | value: updated}, scope}
        error ->
          error
      end
    else
      {:ok, option, scope}
    end
  end

end
