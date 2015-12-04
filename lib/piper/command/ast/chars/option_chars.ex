defimpl String.Chars, for: Piper.Command.Ast.Option do

  use Piper.Command.Ast.Chars.Util
  alias Piper.Command.Ast.Option

  def to_string(%Option{flag: flag, value: nil}) do
    flag = "#{flag}"
    case String.length(flag) == 1 do
      true ->
        "-#{flag}"
      false ->
        "--#{flag}"
    end
  end

  def to_string(%Option{flag: flag, value: value}) do
    flag = "#{flag}"
    case String.length(flag) == 1 do
      true ->
        "-#{flag}=#{escape(value)}"
      false ->
        "--#{flag}=#{escape(value)}"
    end
  end

end