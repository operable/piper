defmodule Piper.Command.Ast.BadValueError do

  defexception [:name, :value]

  def message(%__MODULE__{name: name, value: value}) do
    "#{inspect value, pretty: true} bound to #{name} instead of expected scalar."
  end

end
