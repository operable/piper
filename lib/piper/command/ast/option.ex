defmodule Piper.Command.Ast.Option do

  defstruct [name: nil, value: nil, opt_type: nil, needs_value: false]

  def new(opts) do
    name = Keyword.fetch!(opts, :name)
    value = Keyword.get(opts, :value)
    needs_value = Keyword.get(opts, :needs_value, false)
    {opt_type, offset} = if String.starts_with?(name, "--") do
      {:long, 2}
    else
      {:short, 1}
    end
    name = String.slice(name, offset, String.length(name))
    %__MODULE__{name: name, value: value, opt_type: opt_type, needs_value: needs_value}
  end

  def set_value(%__MODULE__{}=opt, value) do
    %{opt | value: value}
  end

end
