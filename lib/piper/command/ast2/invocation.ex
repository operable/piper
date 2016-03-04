defmodule Piper.Command.Ast2.Invocation do

  alias Piper.Command.Ast2

  defstruct [name: nil, args: [], redir: nil]

  def new(%Ast2.Name{}=name, opts \\ []) do
    args = Keyword.get(opts, :args, [])
    redir = Keyword.get(opts, :redir)
    %__MODULE__{name: name, args: args, redir: redir}
  end

end

defmodule Piper.Command.Ast2.InvocationConnector do

  alias Piper.Command.Ast2

  defstruct [line: nil, col: nil, left: nil, right: nil, type: nil]

  def new({type, {line, col}, _}, left, right) when type in [:pipe, :iff] do
    %__MODULE__{line: line, col: col, left: left, right: right, type: type}
  end

end
