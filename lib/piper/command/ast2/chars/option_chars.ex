defimpl String.Chars, for: Piper.Command.Ast2.Option do

  alias Piper.Command.Ast2.Option

  def to_string(%Option{name: name, value: nil, opt_type: :short}) do
    "-#{name}"
  end
  def to_string(%Option{name: name, value: value, opt_type: :short}) do
    "-#{name} #{value}"
  end
  def to_string(%Option{name: name, value: nil, opt_type: :long}) do
    "--#{name}"
  end
  def to_string(%Option{name: name, value: value, opt_type: :long}) do
    "--#{name}=#{value}"
  end

end
