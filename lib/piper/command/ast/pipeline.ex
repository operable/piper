defmodule Piper.Command.Ast.Pipeline do

  defstruct [:head]

  def new(chain) do
    %__MODULE__{head: chain}
  end

end
