defimpl String.Chars, for: Piper.Ast.Invocation do

  alias Piper.Ast

  def to_string(%Ast.Invocation{command: command, args: args, options: options}) do
    formatted_opts = for {_, opt} <- options do
      "#{opt}"
    end
    formatted_args = for arg <- args do
      "#{arg}"
    end
    formatted_command = ["#{command}"|formatted_opts] ++ formatted_args
    Enum.join(formatted_command, " ")
  end

end
