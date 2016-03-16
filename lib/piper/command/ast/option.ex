defmodule Piper.Command.Ast.Option do

  defstruct [name: nil, value: nil, opt_type: nil]

  def new(opts) do
    name = Keyword.fetch!(opts, :name)
    value = Keyword.get(opts, :value)
    opt_type = Keyword.fetch!(opts, :type)
    %__MODULE__{name: name, value: value, opt_type: opt_type}
  end

  def set_value(%__MODULE__{}=opt, value) do
    %{opt | value: value}
  end

end
