defmodule Piper.Command.Ast.Redirect do

  alias Piper.Command.Ast.Util

  defstruct [line: nil, col: nil, type: nil, targets: nil]

  def new({type, meta, _}, targets) when type in [:redir_one, :redir_multi] do
    {line, col} = Util.position(meta)
    %__MODULE__{line: line, col: col, type: type, targets: List.wrap(targets)}
  end

end
