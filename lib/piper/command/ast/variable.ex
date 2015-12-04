defmodule Piper.Command.Ast.Variable do

  use Piper.Util.TokenWrapper

  defwrapper [value: :name, token_type: [:variable, :optvar],
              others: [:index, :value]]

  def set_index(%__MODULE__{}=var, index) do
    %{var | index: index}
  end

end
