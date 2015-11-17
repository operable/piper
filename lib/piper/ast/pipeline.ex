defmodule Piper.Ast.Pipeline do

  alias Piper.Ast
  alias Piper.Util.Token

  defstruct [:line, :col, :text, :type, :invocations, :output_to_input, :abort_on_error]

  def new(%Token{type: type}=token) when type in [:iff, :pipe] do
    %__MODULE__{line: token.line, col: token.col,
                text: token.text, type: token.type,
                invocations: [],
                output_to_input: (token.type == :pipe),
                abort_on_error: true}
  end

  def add_invocation(%__MODULE__{invocations: invocations}=pipeline, %Ast.Invocation{}=invocation) do
    %{pipeline | invocations: invocations ++ [invocation]}
  end

  def add_pipeline(%__MODULE__{invocations: invocations}=pipeline, %__MODULE__{}=next) do
    %{pipeline | invocations: invocations ++ [next]}
  end

end
