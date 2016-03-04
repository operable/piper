defmodule Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  defstruct [:head]

  def new(chain) do
    %__MODULE__{head: chain}
  end

end
