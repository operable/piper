defmodule Piper.Command.Ast.Invocation do

  alias Piper.Util.Token
  alias Piper.Command.Ast

  defstruct [line: nil, col: nil, command: nil, args: [], options: [],
             redirs: []]

  def new(%Token{type: :ns_name}=token) do
    %__MODULE__{line: token.line, col: token.col,
                command: token.text}
  end
  def new(%Token{type: :string}=token) do
    %__MODULE__{line: token.line, col: token.col,
                command: token.text}
  end
  def new(%Ast.Variable{line: line, col: col}=var) do
    %__MODULE__{line: line, col: col, command: var}
  end
  def add_arg(%__MODULE__{args: args}=invocation, arg) do
    %{invocation | args: args ++ [arg]}
  end

  def bundle_name(%__MODULE__{command: command}) do
    case String.split(command, "::") do
      [bundle, _command] ->
        bundle
      [_] ->
        hd(String.split(command, ":"))
    end
  end

  def command_name(%__MODULE__{command: command}) do
    case String.split(command, "::") do
      [_bundle, command] ->
        ":" <> command
      [_] ->
        [_bundle, command] = String.split(command, ":")
        command
    end
  end

  def add_redir(%__MODULE__{redirs: redirs}=invocation, dest) when is_binary(dest) do
    if Enum.member?(redirs, dest) do
      invocation
    else
      %{invocation | redirs: [dest|redirs]}
    end
  end

  def add_redirs(%__MODULE__{redirs: redirs}=invocation, dests) when is_list(dests) do
    updated = Enum.reduce(dests, redirs,
      fn(dest, acc) ->
        if Enum.member?(acc, dest) do
          acc
        else
          [dest|acc]
        end end)
    %{invocation | redirs: updated}
  end

end
