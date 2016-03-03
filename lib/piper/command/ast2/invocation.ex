defmodule Piper.Command.Ast2.Invocation do

  alias Piper.Command.Ast2

  defstruct [name: nil, orig_args: [], args: [], options: [], redir: nil]

  def new(%Ast2.Name{}=name, opts \\ []) do
    args = Keyword.get(opts, :args, [])
    orig_args = args
    {options, args} = Enum.partition(args, fn(%Ast2.Option{}) -> true
      (_) -> false
    end)
    redir = Keyword.get(opts, :redir)
    %__MODULE__{name: name, orig_args: orig_args, args: args, options: options, redir: redir}
  end

  def add_arg(%__MODULE__{args: args}=invocation, arg) do
    %{invocation | args: args ++ [arg]}
  end

  def add_option(%__MODULE__{options: options}=invocation, option) do
    %{invocation | options: options ++ [option]}
  end

end

defmodule Piper.Command.Ast2.InvocationConnector do

  alias Piper.Command.Ast2

  defstruct [line: nil, col: nil, left: nil, right: nil, type: nil]

  def new({type, {line, col}, _}, left, right) when type in [:pipe, :iff] do
    %__MODULE__{line: line, col: col, left: left, right: right, type: type}
  end

end
