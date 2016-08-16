defmodule Piper.Command.Ast.BadValueError do

  defexception [:name, :value]

  def message(%__MODULE__{name: name, value: value}) do
    text_value = case Poison.encode(value) do
                   {:ok, text} ->
                     text
                   _ ->
                     "#{inspect value, pretty: true}"
                 end
    "#{text_value} bound to $#{name} instead of expected scalar value."
  end

end
