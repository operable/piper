defmodule Piper.Command.Ast.Variable do

  use Piper.Util.TokenWrapper

  defwrapper [value: :name, token_type: [:variable, :optvar],
              others: [:index, :value, :binding_hook]]

  def set_index(%__MODULE__{}=var, index) do
    %{var | index: index}
  end

  def set_binding_hook(%__MODULE__{}=var, hook) when is_function(hook) do
    %{var | binding_hook: hook}
  end

end
