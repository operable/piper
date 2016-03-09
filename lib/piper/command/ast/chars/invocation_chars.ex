defimpl String.Chars, for: Piper.Command.Ast.Invocation do

  alias Piper.Command.Ast

  def to_string(%Ast.Invocation{name: name, args: args, redir: redir}) do
    formatted_args = if Enum.empty?(args) do
      ""
    else
      " " <> Enum.join(Enum.map(args, &("#{&1}")), " ")
    end
    formatted_command = "#{name}#{formatted_args}"
    if redir == nil do
      formatted_command
    else
      formatted_command <> " #{redir}"
    end
  end

end

defimpl String.Chars, for: Piper.Command.Ast.PipelineStage do

  alias Piper.Command.Ast

  def to_string(%Ast.PipelineStage{left: left, right: nil}) do
    "#{left}"
  end
  def to_string(%Ast.PipelineStage{type: type, left: left, right: right}) do
    left = String.strip("#{left}")
    right = String.strip("#{right}")
    left <> " #{symbol_for_type(type)} " <> right
  end

  defp symbol_for_type(:iff) do
    "&&"
  end
  defp symbol_for_type(:pipe) do
    "|"
  end

end
