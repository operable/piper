defmodule Piper.Command.Ast.Redirect do

  defstruct [line: nil, col: nil, type: nil, targets: nil]

  def new({type, {line, col}, _}, targets) when type in [:redir_one, :redir_multi] do
    %__MODULE__{line: line, col: col, type: type, targets: List.wrap(targets)}
  end

end
