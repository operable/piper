defmodule Piper.Command.Ast.PipelineStage do

  alias Piper.Command.Ast

  defstruct [line: nil, col: nil, left: nil, right: nil, type: nil]

  def new({type, {line, col}, _}, %Ast.PipelineStage{right: nil}=left, %Ast.PipelineStage{}=right) do
    %{left | type: type, line: line, col: col, right: right}
  end
  def new({type, {line, col}, _}, left, right) when type in [:pipe, :iff] do
    %__MODULE__{line: line, col: col, left: left, right: right, type: type}
  end

  def new(%__MODULE__{}=stage) do
    stage
  end
  def new(left) do
    %__MODULE__{line: 0, col: 0, left: left}
  end

end
