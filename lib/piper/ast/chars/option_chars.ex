defimpl String.Chars, for: Piper.Ast.Option do

  alias Piper.Ast.Option

  def to_string(%Option{flag: flag, value: nil}) do
    case String.length(flag) == 1 do
      true ->
        "-#{flag}"
      false ->
        "--#{flag}"
    end
  end

  def to_string(%Option{flag: flag, value: value}) do
    case String.length(flag) == 1 do
      true ->
        "-#{flag}=#{value}"
      false ->
        "--#{flag}=#{value}"
    end
  end

end
