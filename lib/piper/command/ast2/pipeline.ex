defmodule Piper.Command.Ast2.Pipeline do

  alias Piper.Command.Ast2

  defstruct [:head]

  def new(chain) do
    %__MODULE__{head: chain}
  end

end
