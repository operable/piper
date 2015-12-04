defimpl String.Chars, for: [Piper.Permissions.Ast.String,
                            Piper.Permissions.Ast.Integer,
                            Piper.Permissions.Ast.Float,
                            Piper.Permissions.Ast.Bool,
                            Piper.Permissions.Ast.List,
                            Piper.Permissions.Ast.Regex,
                            Piper.Permissions.Ast.Arg,
                            Piper.Permissions.Ast.Option] do

  alias Piper.Permissions.Ast

  def to_string(%Ast.String{value: value, quotes: nil}) do
    "#{value}"
  end
  def to_string(%Ast.String{value: value, quotes: quotes}) do
    "#{quotes}#{value}#{quotes}"
  end
  def to_string(%Ast.Integer{value: value}) do
    "#{value}"
  end
  def to_string(%Ast.Float{value: value}) do
    "#{value}"
  end
  def to_string(%Ast.Bool{value: true}) do
    "true"
  end
  def to_string(%Ast.Bool{value: false}) do
    "false"
  end
  def to_string(%Ast.List{values: values}) do
    "[" <> Enum.join(Enum.map(values, &("#{&1}")), ", ") <> "]"
  end
  def to_string(%Ast.Regex{value: value}) do
    "/#{value.source}/"
  end
  def to_string(%Ast.Arg{index: :any}) do
    "any arg"
  end
  def to_string(%Ast.Arg{index: :all}) do
    "all arg"
  end
  def to_string(%Ast.Arg{index: index}) do
    "arg[#{index}]"
  end
  def to_string(%Ast.Option{name: :any}) do
    "any option"
  end
  def to_string(%Ast.Option{name: :all}) do
    "all option"
  end
  def to_string(%Ast.Option{name: name}) do
    "option[#{name}]"
  end
end
