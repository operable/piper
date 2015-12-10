defimpl String.Chars, for: Piper.Command.Ast.Invocation do

  use Piper.Command.Ast.Chars.Util

  alias Piper.Command.Ast

  def to_string(%Ast.Invocation{command: command, args: args, options: options,
                                redirs: redirs}) do
    formatted_opts = for {_, opt} <- options do
      "#{opt}"
    end
    formatted_args = for arg <- args do
      "#{escape(arg)}"
    end
    formatted_command = ["#{command}"|formatted_opts] ++ formatted_args
    formatted_command = format_redirs(formatted_command, redirs)
    Enum.join(formatted_command, " ")
  end

  defp format_redirs(command, []),
  do: command
  defp format_redirs(command, [_]=dests) do
    command ++ [">"|dests]
  end
  defp format_redirs(command, dests) do
    command ++ ["*>"|dests]
  end

end
