defmodule Piper.Command.Ast.Util do

  def position(meta), do: Keyword.fetch!(meta, :position)

  def type_hint(meta), do: Keyword.get(meta, :hint, :none)

end
